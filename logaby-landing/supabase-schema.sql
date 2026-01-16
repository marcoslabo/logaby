-- Waitlist table for analytics tracking (optional)
-- This is only needed if you want to track signups in Supabase alongside ConvertKit

CREATE TABLE IF NOT EXISTS waitlist (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    signup_number INTEGER,
    convertkit_subscriber_id TEXT,
    source TEXT DEFAULT 'direct',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_waitlist_signup_number ON waitlist(signup_number);
CREATE INDEX IF NOT EXISTS idx_waitlist_created_at ON waitlist(created_at);

-- Enable Row Level Security
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public inserts (for form submissions)
CREATE POLICY "Allow public inserts" ON waitlist
    FOR INSERT
    WITH CHECK (true);

-- Policy: No public reads (only you can see the data via dashboard)
CREATE POLICY "No public reads" ON waitlist
    FOR SELECT
    USING (false);

-- Optional: Create a view for analytics (accessible only to authenticated users)
CREATE OR REPLACE VIEW waitlist_stats AS
SELECT 
    COUNT(*) as total_signups,
    COUNT(*) FILTER (WHERE signup_number <= 50) as early_bird_signups,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as signups_last_7_days,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 day') as signups_last_24h
FROM waitlist;
