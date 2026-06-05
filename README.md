# MOZ × SOCi H2 2026 Plan

Interactive planning tracker for the MOZ partnership. Built with vanilla HTML/JS + Supabase.

## Setup

1. Create a Supabase project at supabase.com
2. In SQL Editor, paste the contents of `supabase/schema.sql` and run
3. Go to Settings → API and copy your Project URL + anon public key
4. Edit `index.html` and replace:
   - `SUPABASE_URL` with your Project URL
   - `SUPABASE_ANON_KEY` with your anon key
5. Push to GitHub, enable GitHub Pages

## Deployment

- Static site on GitHub Pages
- All data lives in Supabase (Postgres)
- Auth via Supabase email/password
- Free tier: 5GB egress/mo, 500MB storage, auto-pause after 7 days inactivity

## First Login

1. Sign up with your email
2. In Supabase SQL Editor, promote yourself:
```sql
   update profiles set role = 'editor' where email = 'your@email.com';
```
3. Refresh the app. Plan auto-seeds and you're in.
