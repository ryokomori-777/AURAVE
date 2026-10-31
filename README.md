# AURAVE v3.5 — Supabase-connected build

## What's connected
- Supabase anonymous sign-in (no email/password form; the browser keeps the anonymous session).
- Shared profiles (nickname + avatar URL) in `public.profiles`.
- Shared reviews and replies in `public.reviews` and `public.review_replies`.
- Review attachments uploaded to the public `aurave-community` Storage bucket.
- Existing server-side daily review trigger remains responsible for the 3/day limit.

## Before publishing
1. In Supabase, confirm **Authentication → Sign In / Providers → Allow anonymous sign-ins** is enabled and saved.
2. The main `SUPABASE_SETUP.sql` migration from the preparation package must already have run successfully.
3. Run `SUPABASE_IMAGES_MIGRATION.sql` once in Supabase SQL Editor. It adds `reviews.images` for the uploaded image URLs.
4. Publish the contents of this folder to the root of the existing GitHub Pages repository (keep the `assets/` folder beside `index.html`).

The browser bundle contains only the Supabase Project URL and Publishable key. Never put an `sb_secret_...` key in this site.

## Important limitations / security notes
- Anonymous sessions are device/browser-bound. Clearing site data or changing devices can lose access to that anonymous identity.
- Nickname availability is checked by the client for convenience; the database's case-insensitive unique index is the final duplicate guard. A race may still produce a database error shown to the user.
- The reserved owner nickname and verified badge are deliberately not granted based on the visible nickname alone. Bind the owner's Supabase auth UUID to a protected server-side owner record before enabling the badge.
- The text moderation filter is client-side convenience, not a security boundary.
- The cart remains local to the browser; checkout is not implemented.
