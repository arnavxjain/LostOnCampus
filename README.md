# Lost on Campus

A campus lost & found app built with Flutter and Supabase.

1. An **owner** posts a lost item (title, optional description and photo, category).
2. A **finder** hands the item to any security guard, taps **I Found This** and writes a note saying which desk has it.
3. A **6-digit pickup code** is generated immediately. The owner gets a live notification and sees the code; every security **admin** sees it too. The finder never does.
4. The owner tells the guard the code, the guard finds the matching item, hands it over and taps **Trace complete**. No matching code, no handover.

## Tech

| | |
|---|---|
| App | Flutter 3.44 (Dart 3.12), Riverpod 3, go_router 18 |
| Backend | Supabase: Auth (email + 6-digit code), Postgres with RLS, Storage, Realtime |
| Config | `flutter_dotenv` (`.env`, never committed) |

## Project structure

```
lib/
  core/            config (env), router, Supabase client, theme
  features/
    auth/          register, login, email code verification, role lookup
    items/         feed, post, item detail, My posts, Found sheet
    guard/         admin (security) dashboard, OTP matching, Trace complete
    notifications/ notifications tab + live ping
  shared/          models, widgets, utils
supabase/
  migrations/      SQL, run in order
  tests/           database tests (RLS + OTP flow) in an in-memory Postgres
test/              Flutter unit tests
docs/TESTING.md    manual test checklist
```

## Setup

### 1. Flutter

```bash
flutter pub get
```

### 2. Supabase project

Create a project at [supabase.com](https://supabase.com), then:

**Environment keys:** copy `.env.example` to `.env` and fill in values from *Project Settings → API*:

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=<publishable or anon key>
```

`.env` is bundled into the app, so only ever use the public publishable/anon key. Never put the secret / `service_role` key in it.

**Database:** in *SQL Editor*, run each file in `supabase/migrations/` **in filename order**, once each:

1. `20261018000000_init_schema.sql` creates the tables, RLS, the `item-images` bucket and the profile-on-signup trigger
2. `20261019000000_admin_handover_flow.sql` adds the admin role, Found / Trace complete functions and pickup codes
3. `20261020000000_notifications.sql` adds notifications and their trigger

The dashboard may warn about "destructive operations" for migration 2; that's expected (it removes the old per-floor setup).

**Email sign-in:** *Authentication → Sign In / Providers → Email*: enable it and keep **Confirm email** on.

**Email code template:** *Authentication → Emails → Templates → Confirm signup*. The app expects a 6-digit code, not a link:

```html
<h2>Confirm your email</h2>
<p>Your Lost on Campus code is:</p>
<p style="font-size:28px;font-weight:bold;letter-spacing:4px">{{ .Token }}</p>
```

Also check the email OTP length is **6**.

**Sending email (Resend):** Supabase's built-in email is for testing only. Under *Authentication → Emails → SMTP Settings*:

| Field | Value |
|---|---|
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` |
| Password | your Resend API key |
| Sender email | an address on a **verified** Resend domain, e.g. `no-reply@mail.yourdomain.com` |

Without a verified domain, Resend only delivers to your own Resend account email, and sign-ups to other addresses fail.

**Realtime:** the migrations add `items` and `notifications` to the `supabase_realtime` publication. Check under *Database → Publications* if live updates don't arrive.

### 3. Run

```bash
flutter run
```

## Making a security (admin) account

Admins log in on the same screen as students. Nobody can make themselves an admin from the app.

1. The person signs up and confirms their email in the app as usual.
2. In Supabase, either change their `role` to `admin` in *Table Editor → profiles*, or run:

```sql
update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'security@example.com');
```

3. They sign out and back in to land on the **Security desk** screen.

Set `role = 'student'` to undo. Use separate accounts for security staff: an admin account can't post or report items.

## Tests

**Flutter unit tests** (validators, models, routing/role access, OTP matching, error messages):

```bash
flutter test
```

**Database tests**: run all migrations in an in-memory Postgres and check every RLS rule, the Found → code → Trace complete flow, and notifications, as owner, finder, bystander and admin:

```bash
cd supabase/tests && npm install && npm test
```

**Manual end-to-end checklist:** [docs/TESTING.md](docs/TESTING.md).

## Security model (summary)

- Item, handover and role changes never come straight from the app: column privileges block them, and status changes go through the `report_found` / `complete_handover` database functions or triggers.
- Pickup codes live in `handover_codes`, readable only by the item's owner and admins. Notifications never contain the code.
- Active codes are unique, so a code always identifies exactly one item.
- Photos are publicly readable by URL; users can only upload or delete inside their own folder.
