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

        // Build prompt for Claude
        const prompt = `You are a baby activity log parser. Parents speak naturally to log their baby's activities. Understand their INTENT, not just exact words. Return ONLY valid JSON.

Input: "${voice_input}"

Activity types to detect:
- feeding: bottle feeding with oz amount
- nursing: breastfeeding with duration and side(s)
- diaper: diaper change (wet/dirty/mixed)
- sleep_start: baby is going to sleep NOW
- sleep_end: baby just woke up
- sleep_completed: a nap that already happened with start AND end times
- weight: baby's weight measurement
- pumping: breast pumping with oz and side

JSON schema (omit fields that don't apply):
{
  "type": string,
  "amount_oz": number,
  "duration_minutes": number,
  "side": "left" | "right" | "both",
  "content": "formula" | "breastmilk",
  "diaper_type": "wet" | "dirty" | "mixed",
  "weight_lbs": number,
  "start_hour": number (0-23),
  "start_minute": number,
  "end_hour": number (0-23),
  "end_minute": number
}

SLEEP RULES (important!):
- "going to sleep", "putting down", "starting nap" → sleep_start
- "woke up", "is awake", "nap ended" → sleep_end  
- "slept from X to Y", "napped X to Y" (BOTH times given) → sleep_completed with start_hour AND end_hour
- If someone says "slept" in past tense with both times, that's sleep_completed!

NATURAL LANGUAGE - understand these variations:
Feeding: "ate 3 oz", "drank a bottle", "had 4 ounces of formula", "gave her 2oz", "she ate"
Nursing: "nursed 15 min", "breastfed both sides", "fed from the left", "latched for 20 minutes"
Diaper: "poopy diaper", "wet one", "changed him", "dirty diaper", "number two"
Sleep: "she's down", "taking a nap", "just woke up", "slept 2 hours", "napped from 1 to 3"
Weight: "weighs 8 lbs 6 oz", "came in at 9 pounds", "weight check 8.5 lbs"
Pumping: "pumped 4 oz", "expressed 3 ounces from left"

Examples:
"she ate 2 oz" → {"type":"feeding","amount_oz":2}
"nursed both sides for 15 mins" → {"type":"nursing","duration_minutes":15,"side":"both"}
"poopy diaper" → {"type":"diaper","diaper_type":"dirty"}
"little one is down for a nap" → {"type":"sleep_start"}
"she woke up" → {"type":"sleep_end"}
"slept from 10am to 2pm" → {"type":"sleep_completed","start_hour":10,"start_minute":0,"end_hour":14,"end_minute":0}
"baby weighs 8 lbs 6 oz" → {"type":"weight","weight_lbs":8.375}`;

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
