-- ============================================================
-- BeerBuddy – Migration 002: Ghost Mode, Push Tokens, GDPR
-- ============================================================
-- Pillar 5: Ghost Mode (is_ghost flag + RLS)
-- Pillar 6: Age verification, FCM token, GDPR hard-delete
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. PROFILES: nové sloupce pro compliance + push notifikace
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS age_verified_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS ghost_mode       BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS fcm_token        TEXT,
  ADD COLUMN IF NOT EXISTS apns_token       TEXT;

-- ────────────────────────────────────────────────────────────
-- 2. BEER_LOGS: Ghost Mode flag
-- ────────────────────────────────────────────────────────────
-- Pokud is_ghost = true:
--   ✓ Započítá se do osobních statistik uživatele
--   ✗ NEPROPÍŠE se do veřejného feedu / žebříčku
--   ✗ NESDÍLÍ se lokace s přáteli
ALTER TABLE public.beer_logs
  ADD COLUMN IF NOT EXISTS is_ghost BOOLEAN NOT NULL DEFAULT false;

-- ────────────────────────────────────────────────────────────
-- 3. RLS: Aktualizace politik pro Ghost Mode
-- ────────────────────────────────────────────────────────────

-- Smazat starou politiku pro přátelské logy
DROP POLICY IF EXISTS beer_logs_friends_select ON public.beer_logs;

-- Nová politika: přátelé vidí jen NE-ghost logy
CREATE POLICY beer_logs_friends_select ON public.beer_logs FOR SELECT
  USING (
    -- Vlastní záznamy (vč. ghost) – řeší stávající beer_logs_select
    -- Záznamy přátel – jen pokud NEJSOU ghost
    (is_ghost = false) AND user_id IN (
      SELECT CASE
        WHEN requester_id = auth.uid() THEN addressee_id
        ELSE requester_id
      END
      FROM public.friendships
      WHERE status = 'accepted'
        AND (requester_id = auth.uid() OR addressee_id = auth.uid())
    )
  );

-- ────────────────────────────────────────────────────────────
-- 4. LEADERBOARD: Přestavba – vyloučení ghost logů
-- ────────────────────────────────────────────────────────────
DROP MATERIALIZED VIEW IF EXISTS public.leaderboard;

CREATE MATERIALIZED VIEW public.leaderboard AS
SELECT
  p.id          AS user_id,
  p.username,
  p.avatar_url,
  COUNT(l.id)   AS total_beers,
  AVG(l.rating)::NUMERIC(3,2) AS avg_rating,
  COUNT(DISTINCT l.venue_name) FILTER (WHERE l.venue_name IS NOT NULL) AS unique_venues
FROM public.profiles p
LEFT JOIN public.beer_logs l
  ON l.user_id = p.id
  AND l.is_ghost = false           -- ← Ghost logy se NEPOČÍTAJÍ do veřejného žebříčku
GROUP BY p.id, p.username, p.avatar_url;

CREATE UNIQUE INDEX idx_leaderboard_user ON public.leaderboard (user_id);

-- ────────────────────────────────────────────────────────────
-- 5. VIEW: Osobní statistiky (VČETNĚ ghost logů)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.my_stats AS
SELECT
  user_id,
  COUNT(*)                             AS total_beers,
  COUNT(*) FILTER (WHERE is_ghost)     AS ghost_beers,
  AVG(rating)::NUMERIC(3,2)           AS avg_rating,
  COUNT(DISTINCT venue_name)
    FILTER (WHERE venue_name IS NOT NULL) AS unique_venues,
  MAX(logged_at)                       AS last_beer_at
FROM public.beer_logs
WHERE user_id = auth.uid()
GROUP BY user_id;

-- ────────────────────────────────────────────────────────────
-- 6. GDPR: Hard-delete funkce (kaskádový výmaz)
-- ────────────────────────────────────────────────────────────
-- Volat přes Edge Function po ověření identity uživatele.
-- Smaže profil → ON DELETE CASCADE smaže beer_logs, friendships,
-- team_members, user_achievements. Pak smaže auth.users záznam.
CREATE OR REPLACE FUNCTION public.gdpr_delete_user(target_user_id UUID)
RETURNS void AS $$
BEGIN
  -- Ověření: uživatel může smazat jen sám sebe
  IF auth.uid() IS DISTINCT FROM target_user_id THEN
    RAISE EXCEPTION 'Unauthorized: can only delete own account';
  END IF;

  -- 1. Smazat profil (CASCADE smaže beer_logs, friendships, atd.)
  DELETE FROM public.profiles WHERE id = target_user_id;

  -- 2. Smazat auth záznam
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ────────────────────────────────────────────────────────────
-- 7. PUSH NOTIFIKACE: Tabulka pro device tokeny
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.push_tokens (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_token UNIQUE (token)
);

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY push_tokens_select ON public.push_tokens FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY push_tokens_insert ON public.push_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY push_tokens_delete ON public.push_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────
-- 8. HELPER: Funkce pro kontrolu překonání v žebříčku
-- ────────────────────────────────────────────────────────────
-- Voláno Edge Function po INSERT do beer_logs.
-- Vrací seznam user_ids přátel, které uživatel právě předběhl.
CREATE OR REPLACE FUNCTION public.check_leaderboard_overtakes(p_user_id UUID)
RETURNS TABLE(overtaken_user_id UUID, overtaken_username TEXT) AS $$
BEGIN
  -- Refresh leaderboard nejdříve
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.leaderboard;

  RETURN QUERY
  SELECT
    lb.user_id,
    lb.username
  FROM public.leaderboard lb
  WHERE lb.user_id IN (
    -- Přátelé uživatele
    SELECT CASE
      WHEN f.requester_id = p_user_id THEN f.addressee_id
      ELSE f.requester_id
    END
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (f.requester_id = p_user_id OR f.addressee_id = p_user_id)
  )
  AND lb.total_beers < (
    SELECT total_beers FROM public.leaderboard WHERE user_id = p_user_id
  )
  AND lb.total_beers >= (
    SELECT total_beers - 1 FROM public.leaderboard WHERE user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
