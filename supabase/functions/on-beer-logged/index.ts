// ═══════════════════════════════════════════════════════════════
// Pillar 4: Edge Function – on-beer-logged
// ═══════════════════════════════════════════════════════════════
//
// Spouštěno Supabase Database Webhookem při INSERT do beer_logs.
//
// Flow:
// 1. Přijme webhook payload s novým beer_log záznamem
// 2. Pokud je ghost → ignorovat (žádné notifikace)
// 3. Zavolá check_leaderboard_overtakes() → seznam předběhnutých
// 4. Pro každého předběhnutého přítele:
//    a. Načte FCM tokeny z push_tokens
//    b. Odešle push notifikaci přes FCM HTTP API v2
//
// Deploy: supabase functions deploy on-beer-logged
// ═══════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";

interface WebhookPayload {
  type: "INSERT";
  table: "beer_logs";
  record: {
    id: number;
    user_id: string;
    beer_name: string;
    is_ghost: boolean;
  };
}

serve(async (req: Request) => {
  try {
    const payload: WebhookPayload = await req.json();
    const { record } = payload;

    // Ghost logy → žádné notifikace
    if (record.is_ghost) {
      return new Response(JSON.stringify({ message: "Ghost log, skipping" }), {
        status: 200,
      });
    }

    // Supabase admin client (obchází RLS)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Zjistit username autora
    const { data: profile } = await supabase
      .from("profiles")
      .select("username")
      .eq("id", record.user_id)
      .single();

    const username = profile?.username ?? "Někdo";

    // Zjistit koho uživatel předběhl v žebříčku
    const { data: overtaken } = await supabase.rpc(
      "check_leaderboard_overtakes",
      { p_user_id: record.user_id }
    );

    if (!overtaken || overtaken.length === 0) {
      return new Response(
        JSON.stringify({ message: "No overtakes" }),
        { status: 200 }
      );
    }

    // Pro každého předběhnutého → push notifikace
    for (const entry of overtaken) {
      const { data: tokens } = await supabase
        .from("push_tokens")
        .select("token")
        .eq("user_id", entry.overtaken_user_id);

      if (!tokens || tokens.length === 0) continue;

      // FCM HTTP API v2 (legacy) – pro každý token
      for (const { token } of tokens) {
        if (!FCM_SERVER_KEY) continue;

        await fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: "🍺 Předběhli tě!",
              body: `${username} tě právě předběhl/a v žebříčku s pivem ${record.beer_name}!`,
            },
            data: {
              type: "leaderboard_overtake",
              overtaker_id: record.user_id,
            },
          }),
        });
      }
    }

    return new Response(
      JSON.stringify({
        message: `Notified ${overtaken.length} overtaken users`,
      }),
      { status: 200 }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
    });
  }
});
