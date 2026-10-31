-- AURAVE v3.5 -> Supabase integration migration
-- Run once in Supabase SQL Editor. This extends existing tables; it does not drop data.

-- Public profile fields
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

-- Public review display fields (identity remains tied to auth.uid())
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

-- Public reply display fields
ALTER TABLE public.review_replies
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

-- Enforce case-insensitive uniqueness for usernames.
CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_unique
  ON public.profiles (lower(username)) WHERE username IS NOT NULL;

-- Public read; users may only write their own profile/reviews/replies.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_replies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_public_read" ON public.profiles;
CREATE POLICY "profiles_public_read" ON public.profiles
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "reviews_public_read" ON public.reviews;
CREATE POLICY "reviews_public_read" ON public.reviews
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "reviews_insert_own" ON public.reviews;
CREATE POLICY "reviews_insert_own" ON public.reviews
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "reviews_delete_own" ON public.reviews;
CREATE POLICY "reviews_delete_own" ON public.reviews
  FOR DELETE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "replies_public_read" ON public.review_replies;
CREATE POLICY "replies_public_read" ON public.review_replies
  FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "replies_insert_own" ON public.review_replies;
CREATE POLICY "replies_insert_own" ON public.review_replies
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "replies_delete_own" ON public.review_replies;
CREATE POLICY "replies_delete_own" ON public.review_replies
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Storage bucket for user avatars and review attachments.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('aurave-community', 'aurave-community', true, 3145728,
        ARRAY['image/png','image/jpeg','image/webp','image/gif'])
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 3145728,
  allowed_mime_types = ARRAY['image/png','image/jpeg','image/webp','image/gif'];

DROP POLICY IF EXISTS "aurave community public read" ON storage.objects;
CREATE POLICY "aurave community public read" ON storage.objects
  FOR SELECT TO anon, authenticated USING (bucket_id = 'aurave-community');
DROP POLICY IF EXISTS "aurave community authenticated upload" ON storage.objects;
CREATE POLICY "aurave community authenticated upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'aurave-community' AND (storage.foldername(name))[1] = auth.uid()::text
  );
DROP POLICY IF EXISTS "aurave community owner delete" ON storage.objects;
CREATE POLICY "aurave community owner delete" ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'aurave-community' AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- NOTE: The existing daily-review trigger/function is intentionally preserved.
-- NOTE: reserve the owner nickname and assign the verified owner by auth user UUID
-- after the first anonymous sign-in. A display nickname alone must never grant a badge.
