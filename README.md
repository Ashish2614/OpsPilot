# OpsPilot

OpsPilot is a business operations and internal help desk SaaS built with React, Express, Supabase PostgreSQL/Auth/Realtime, and Socket.IO. It gives employees a simple request center, agents a focused queue, and administrators a clear view of workspace operations.

## Features

- Supabase Auth with an HTTP-only access-token cookie and admin, agent, and employee roles.
- Ticket lifecycle, server-side search, pagination, assignment, status transitions, comments, history, notifications, and CSV export.
- Role-aware dashboard data, responsive SaaS UI, loading/empty/error states, and an admin user directory.
- PostgreSQL indexes, foreign keys, RLS policies, Helmet, CORS, login rate limiting, input validation, and formula-safe CSV fields.
- SQL migrations, seed data, health endpoint, Supabase Realtime foundation, and a small runnable test suite.

## Run locally on Windows

```powershell
Copy-Item server/.env.example server/.env
npm install
npm run install:all
# Put your Supabase project URL, anon key, and server-only service-role key in server/.env
npx supabase db push
npm run seed --prefix server
npm run dev
```

Open `http://localhost:5173`. Demo accounts use `DemoPass123!`: `avery@opspilot.dev` (admin), `jordan@opspilot.dev` (agent), and `sam@opspilot.dev` (employee). These are development-only credentials; change or remove them before production.

## Supabase setup and environment

Create a Supabase project, copy its Project URL, public anon key, and service-role key into `server/.env`, then apply `supabase/migrations/202610120001_opspilot.sql` in the Supabase SQL editor or with the Supabase CLI. The service-role key is server-only and must never be added to the client. RLS is enabled on every application table; Express still performs explicit role and ownership checks because its service client bypasses RLS. `COOKIE_SAME_SITE=none` requires HTTPS and appropriate CSRF/origin protection when frontend and backend are on different sites.

## Commands

`npm run dev` runs both apps, `npm run build` builds the client, `npm test` runs the server tests, and `npm run seed --prefix server` safely creates Supabase Auth users/profiles and inserts tickets only when the database has no tickets.

## Architecture

The React client talks to the Express REST API with credentialed Axios requests. Express verifies the Supabase Auth access token, loads the relational profile, and applies ownership/RBAC checks before privileged Supabase queries mutate data. Supabase PostgreSQL stores profiles, tickets, comments, notifications, and audit records with foreign keys, indexes, and RLS. Supabase Auth owns identity; Supabase Realtime can distribute authorized table changes to the client, while REST remains the source of truth. A Node scheduled job creates deduplicated due-date notifications.

## Deployment

Build the client with `npm run build --prefix client` and deploy `client/dist` to Vercel or equivalent with SPA fallback. Deploy `server` to Render, Railway, or another Node host using `npm start`, configure the Supabase environment variables, and set `CLIENT_URL` to the deployed frontend. Use Supabase Auth redirect settings, HTTPS, and a production-only seed process. Never expose the service-role key publicly.

## Known limitations / next steps

The current deliverable is a recruiter-ready MVP. Add client-side Supabase Realtime subscriptions with ticket-room authorization, richer analytics charts, invitation email flow, CSRF tokens for cross-site cookie deployments, and full integration tests against a disposable Supabase project before production launch.
