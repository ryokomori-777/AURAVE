-- AURAVE: persist public image URLs attached to reviews.
-- Run once in Supabase SQL Editor after the main setup migration.
ALTER TABLE public.reviews
ADD COLUMN IF NOT EXISTS images jsonb NOT NULL DEFAULT '[]'::jsonb;
