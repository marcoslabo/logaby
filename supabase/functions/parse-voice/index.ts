// Supabase Edge Function: parse-voice
// Proxies voice input to Claude Haiku for parsing
// Deploy: supabase functions deploy parse-voice --no-verify-jwt

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response(null, { headers: corsHeaders });
    }

    try {
        // Get voice input from request
        const { voice_input } = await req.json();

        if (!voice_input) {
            return new Response(
                JSON.stringify({ error: "voice_input is required" }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Build comprehensive prompt for Claude
        const prompt = `You are a baby activity log parser for exhausted parents. They speak naturally (often while holding a crying baby). Understand their INTENT, not just exact words. Return ONLY valid JSON.

Input: "${voice_input}"

ACTIVITY TYPES:
- feeding: bottle feeding with oz/ml amount
- nursing: breastfeeding with duration and side(s)
- diaper: diaper change (wet/dirty/mixed)
- sleep_start: baby starting sleep NOW
- sleep_end: baby just woke up
- sleep_completed: past nap with BOTH start AND end times
- weight: baby's weight
- pumping: breast pumping

JSON SCHEMA (omit fields that don't apply):
{
  "type": string,
  "amount_oz": number (if user says oz),
  "amount_ml": number (if user says ml - return the raw ml number),
  "duration_minutes": number,
  "side": "left" | "right" | "both",
  "content": "formula" | "breastmilk",
  "diaper_type": "wet" | "dirty" | "mixed",
  "weight_lbs": number,
  "start_hour": number (0-23, for time ranges),
  "start_minute": number,
  "end_hour": number (0-23, for time ranges),
  "end_minute": number,
  "at_hour": number (0-23, for "at 2pm" specific times),
  "at_minute": number,
  "hours_ago": number,
  "minutes_ago": number,
  "is_pm": boolean (true if PM explicitly stated)
}

AMOUNT RULES:
- "4 oz" → amount_oz: 4
- "300 ml" → amount_ml: 300 (NOT amount_oz!)
- Always use the unit the user specified

UNIT CONVERSION (CRITICAL - DO THIS FIRST!):
- ml to oz conversion: divide by 30
- "50 ml" → amount_oz: 1.7 (50 ÷ 30)
- "100 ml" → amount_oz: 3.3 (100 ÷ 30)
- "150 ml" → amount_oz: 5.0 (150 ÷ 30)
- "300 ml" → amount_oz: 10.0 (300 ÷ 30)
- NEVER return the ml number as oz!

TIME RULES (CRITICAL! - ALWAYS extract time if mentioned):
- "at 2:20 PM" → at_hour: 14, at_minute: 20
- "at 3pm" → at_hour: 15, at_minute: 0
- "at 10am" → at_hour: 10, at_minute: 0
- "at 12:50 AM" → at_hour: 0, at_minute: 50 (12 AM = midnight = hour 0)
- "at 1:30 AM" → at_hour: 1, at_minute: 30
- "at 5am" → at_hour: 5, at_minute: 0
- "2 hours ago" → hours_ago: 2
- "30 minutes ago" / "30 min ago" → minutes_ago: 30
- "from 2 to 3:30 PM" → start_hour: 14, end_hour: 15, end_minute: 30
- If user mentions a TIME, you MUST include at_hour in the response!

═══ FEEDING (Bottle) ═══
All mean bottle feeding:
- "4 oz", "4 ounces", "four ounces", "120 ml"
- "ate 3 oz", "drank 4 oz", "had 2 ounces"
- "she ate", "he drank", "baby had", "gave her 3oz"
- "finished a bottle", "gave him a bottle"
- "fed her 4oz of formula", "fed him breastmilk"
- "ate 4 oz at 2pm" → include at_hour: 14

═══ NURSING (Breastfeeding) ═══
Key words: nursed, nursing, nurse, breastfed, breastfeeding, latched, latch
- "nursed for 15 mins", "nursed 20 minutes"
- "breastfed both sides", "fed from left breast"
- "nursing right side", "latched left for 10 min"
- "she nursed", "he breastfed"
- "nurse at 2pm" → at_hour: 14
- "nursed from 2 to 2:30pm" → duration calculated from range
- "nursed 30 min ago" → minutes_ago: 30
- Default side: "both" if not specified

═══ DIAPER ═══
wet: "wet diaper", "just wet", "pee diaper", "number one", "peed"
dirty: "poopy diaper", "dirty diaper", "poop", "number two", "pooped", "💩"
mixed: "wet and dirty", "both", "pee and poop"
- "changed her", "changed his diaper" → default wet
- "diaper change" → default wet
- "messy diaper" → dirty

═══ SLEEP ═══
sleep_start: "going to sleep", "going down", "putting down", "starting nap", "she's out", "he's down", "down for a nap", "sleeping now"
- "started sleeping at 4:30" → sleep_start with at_hour: 16, at_minute: 30
- "went down at 2pm" → sleep_start with at_hour: 14
- "fell asleep 30 min ago" → sleep_start with minutes_ago: 30
sleep_end: "woke up", "just woke", "is awake", "up from nap", "waking up", "awake now"
- "woke up at 3pm" → sleep_end with at_hour: 15
sleep_completed (MUST have BOTH times): 
- "slept from 10 to 2", "napped 1 to 3pm"
- "slept 10am to 2pm" → start_hour: 10, end_hour: 14

═══ WEIGHT ═══
- "8 lbs 6 oz" → 8.375 lbs
- "8 pounds 6 ounces" → 8.375 lbs
- "weighs 9 pounds", "weight is 8.5 lbs"
- "came in at 9 lbs", "measured 8 pounds"

═══ PUMPING ═══
Key words: pumped, pumping, pump, expressed
- "pumped 4 oz", "pumped 4 ounces from left"
- "expressed 3oz from right breast"
- "pump session 5oz both sides"
- "pump 60 ml" → amount_ml: 60 (NOT amount_oz!)

EXAMPLES:
"4 oz" → {"type":"feeding","amount_oz":4}
"300 ml formula" → {"type":"feeding","amount_ml":300,"content":"formula"}
"she ate 2 oz at 2pm" → {"type":"feeding","amount_oz":2,"at_hour":14,"at_minute":0}
"nursed at 2:20 PM" → {"type":"nursing","at_hour":14,"at_minute":20,"side":"both"}
"breastfed left side 15 min" → {"type":"nursing","duration_minutes":15,"side":"left"}
"nursed from 2 to 3pm" → {"type":"nursing","start_hour":14,"end_hour":15}
"nursed 30 min ago" → {"type":"nursing","minutes_ago":30,"side":"both"}
"poopy diaper" → {"type":"diaper","diaper_type":"dirty"}
"wet diaper at 1pm" → {"type":"diaper","diaper_type":"wet","at_hour":13}
"she's down" → {"type":"sleep_start"}
"woke up" → {"type":"sleep_end"}
"slept from 10am to 2pm" → {"type":"sleep_completed","start_hour":10,"end_hour":14}
"napped 1 to 3" → {"type":"sleep_completed","start_hour":13,"end_hour":15}
"8 lbs 6 oz" → {"type":"weight","weight_lbs":8.375}
"pumped 4oz left" → {"type":"pumping","amount_oz":4,"side":"left"}`;

        // Call Claude API
        const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": ANTHROPIC_API_KEY!,
                "anthropic-version": "2023-06-01",
            },
            body: JSON.stringify({
                model: "claude-3-haiku-20240307",
                max_tokens: 256,
                messages: [{ role: "user", content: prompt }],
            }),
        });

        if (!claudeResponse.ok) {
            const error = await claudeResponse.text();
            console.error("Claude API error:", error);
            return new Response(
                JSON.stringify({ error: "AI parsing failed" }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const claudeData = await claudeResponse.json();
        const responseText = claudeData.content?.[0]?.text || "";

        // Extract JSON from response
        const jsonMatch = responseText.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
            return new Response(
                JSON.stringify({ error: "Could not parse response" }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const parsed = JSON.parse(jsonMatch[0]);

        return new Response(
            JSON.stringify({ success: true, parsed }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

    } catch (error) {
        console.error("Error:", error);
        return new Response(
            JSON.stringify({ error: (error as Error).message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
