-- ============================================================
-- BeerBuddy – Supabase/PostgreSQL Database Schema
-- ============================================================
-- Rozšiřuje auth.users o veřejný profil, katalog piv,
-- záznamy o vypití, přátelství, týmy a achievement systém.
-- ============================================================

-- ------------------------------------------------
-- 1. PROFILES  (rozšíření auth.users)
-- ------------------------------------------------
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url  TEXT,
  bio         TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Automaticky vytvořit profil po registraci
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || REPLACE(NEW.id::text, '-', '')),
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'Nový pivoňka')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------
-- 2. BEERS  (katalog piv)
-- ------------------------------------------------
CREATE TABLE public.beers (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        TEXT NOT NULL,
  brewery     TEXT,
  style       TEXT,          -- IPA, Lager, Stout ...
  abv         REAL,          -- % alkoholu
  image_url   TEXT,
  created_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_beers_name ON public.beers (name);
CREATE INDEX idx_beers_style ON public.beers (style);

-- ------------------------------------------------
-- 3. BEER_LOGS  (záznam o vypití – klíčová tabulka)
-- ------------------------------------------------
CREATE TABLE public.beer_logs (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  beer_id     BIGINT REFERENCES public.beers(id),
  beer_name   TEXT NOT NULL,       -- denormalizace pro rychlý offline přístup
  rating      SMALLINT CHECK (rating BETWEEN 1 AND 5),
  note        TEXT,
  image_url   TEXT,
  latitude    DOUBLE PRECISION,
  longitude   DOUBLE PRECISION,
  venue_name  TEXT,                 -- název hospody (volitelně)
  logged_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_beer_logs_user ON public.beer_logs (user_id);
CREATE INDEX idx_beer_logs_logged_at ON public.beer_logs (logged_at DESC);
CREATE INDEX idx_beer_logs_location ON public.beer_logs
  USING GIST (ll_to_earth(latitude, longitude))
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- ------------------------------------------------
-- 4. FRIENDSHIPS  (obousměrné přátelství)
-- ------------------------------------------------
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'blocked');

CREATE TABLE public.friendships (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  requester_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  addressee_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status        friendship_status NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT no_self_friendship CHECK (requester_id != addressee_id),
  CONSTRAINT unique_friendship UNIQUE (requester_id, addressee_id)
);

CREATE INDEX idx_friendships_addressee ON public.friendships (addressee_id);

-- ------------------------------------------------
-- 5. TEAMS  (skupiny/týmy pro soutěžení)
-- ------------------------------------------------
CREATE TABLE public.teams (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  avatar_url  TEXT,
  owner_id    UUID NOT NULL REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.team_members (
  team_id   BIGINT NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role      TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (team_id, user_id)
);

-- ------------------------------------------------
-- 6. ACHIEVEMENTS  (odznaky / gamifikace)
-- ------------------------------------------------
CREATE TABLE public.achievements (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  key         TEXT UNIQUE NOT NULL,     -- např. 'first_beer', 'pub_crawler_10'
  title       TEXT NOT NULL,
  description TEXT,
  icon_url    TEXT,
  threshold   INT NOT NULL DEFAULT 1    -- kolik akcí je potřeba
);

CREATE TABLE public.user_achievements (
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id BIGINT NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, achievement_id)
);

-- ------------------------------------------------
-- 7. LEADERBOARD VIEW  (materialized pro rychlost)
-- ------------------------------------------------
CREATE MATERIALIZED VIEW public.leaderboard AS
SELECT
  p.id         AS user_id,
  p.username,
  p.avatar_url,
  COUNT(l.id)  AS total_beers,
  AVG(l.rating)::NUMERIC(3,2) AS avg_rating,
  COUNT(DISTINCT l.venue_name) FILTER (WHERE l.venue_name IS NOT NULL) AS unique_venues
FROM public.profiles p
LEFT JOIN public.beer_logs l ON l.user_id = p.id
GROUP BY p.id, p.username, p.avatar_url;

CREATE UNIQUE INDEX idx_leaderboard_user ON public.leaderboard (user_id);

-- Refresh funkce (volat přes Supabase Edge Function / pg_cron)
CREATE OR REPLACE FUNCTION public.refresh_leaderboard()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.leaderboard;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------
-- 8. ROW LEVEL SECURITY  (RLS)
-- ------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beer_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- Profily: čtení pro všechny, editace vlastní
CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (true);
CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Piva (katalog): čtení pro všechny, vkládání pro přihlášené
CREATE POLICY beers_select ON public.beers FOR SELECT USING (true);
CREATE POLICY beers_insert ON public.beers FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Logy: vlastní záznamy
CREATE POLICY beer_logs_select ON public.beer_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY beer_logs_insert ON public.beer_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY beer_logs_delete ON public.beer_logs FOR DELETE USING (auth.uid() = user_id);

-- Přátelství: vidí oba účastníci
CREATE POLICY friendships_select ON public.friendships FOR SELECT
  USING (auth.uid() IN (requester_id, addressee_id));
CREATE POLICY friendships_insert ON public.friendships FOR INSERT
  WITH CHECK (auth.uid() = requester_id);
CREATE POLICY friendships_update ON public.friendships FOR UPDATE
  USING (auth.uid() = addressee_id);

-- Týmy: čtení pro členy
CREATE POLICY teams_select ON public.teams FOR SELECT USING (true);
CREATE POLICY teams_insert ON public.teams FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Členství: čtení pro členy týmu
CREATE POLICY team_members_select ON public.team_members FOR SELECT USING (
  user_id = auth.uid() OR team_id IN (
    SELECT team_id FROM public.team_members WHERE user_id = auth.uid()
  )
);

-- Achievementy: čtení vlastních
CREATE POLICY user_achievements_select ON public.user_achievements FOR SELECT
  USING (auth.uid() = user_id);

-- Logy přátel: rozšíření SELECT pravidla pro přátele
CREATE POLICY beer_logs_friends_select ON public.beer_logs FOR SELECT
  USING (
    user_id IN (
      SELECT CASE
        WHEN requester_id = auth.uid() THEN addressee_id
        ELSE requester_id
      END
      FROM public.friendships
      WHERE status = 'accepted'
        AND (requester_id = auth.uid() OR addressee_id = auth.uid())
    )
  );
