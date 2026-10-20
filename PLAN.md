# plan.md — Campus Lost & Found (Flutter + Supabase)

## 0. Instructions for Claude Code
- Build in phases, in order. After each phase, stop, summarize changes, and wait for my approval.
- Flutter (latest stable), Dart null-safety, `supabase_flutter`, Riverpod for state, `go_router` for navigation.
- Keep secrets in `.env` (flutter_dotenv); never hardcode keys.
- Folder structure: `lib/core`, `lib/features/{auth,items,claims,guard,notifications}`, `lib/shared`.

## 1. How the App Works (reference flow)
1. **Owner** loses an item and posts it: title (required), description (optional), image (optional), category.
2. **Finder** comes across the item and hands it to a **security guard** on any floor.
3. Finder opens the post, taps **"I Found This"** and writes a **mandatory note** saying which floor's guard has it.
4. Immediately: the item is marked **"With security"**, a **6-digit OTP** is generated for it, and the **owner gets a live ping**. The owner's post shows the new tag, the finder's note and the OTP.
5. **Security guards** log in through the same login page with **admin** accounts. They see every item, and each handed-over item with its OTP. The finder never sees the OTP.
6. Owner goes to that guard and tells them the OTP.
7. Guard types the OTP; the matching item appears. If no item matches, nothing is handed over. Guard hands over the matching item and taps **"Trace complete"**. Item is marked **returned**.

## 2. Project Setup ✅
- Create Flutter project, add dependencies, init Supabase in `main.dart`.
- Theme, routing skeleton, role-based auth-guarded routes (student vs admin).

## 3. Authentication (Supabase) ✅
- Registration: name, email, password, phone number (stored, not verified).
- Email confirmation with a 6-digit code (Supabase "Confirm signup" template uses `{{ .Token }}`).
- Login: email + password.
- Session persistence, logout, error and loading states.
- Roles: `student` (default) and `admin` (security staff). Admin accounts are set manually in the DB (no self sign-up as admin).

## 4. Database Schema (SQL migrations) ✅
- `profiles`: id (FK auth.users), full_name, phone, role (`student` | `admin`), created_at.
- `items`: id, owner_id, title, description (nullable), category, image_url (nullable), status (`lost` | `at_security` | `returned`), created_at.
- `handovers`: id, item_id, finder_id, note (mandatory: where it was left), status (`at_security` | `collected`), completed_by (admin), created_at, collected_at.
- `handover_codes`: handover_id, 6-digit code, active. Active codes are unique.
- Storage bucket `item-images` (public read, owner-folder writes).
- Row Level Security:
    - Logged-in users can read `lost` items.
    - Only owners edit or delete their items (delete only while `lost`).
    - Owner can read the OTP for their own item; admins can read all OTPs; finders never can.
    - Admins can read all items and handovers.
    - Handovers are created and completed only through server functions (`report_found`, `complete_handover`).

## 5. Lost Item Posting (Owner) ✅
- Post form: title, optional description, optional image (image_picker → Supabase Storage), category.
- Feed of lost items with search and category filter. Item detail screen.
- "My Posts" screen showing status, the finder's note, and the OTP once the item is with security.

## 6. Found Flow + Admin Dashboard + Live Ping ✅
- "I Found This" on item detail (hidden for the owner and for admins) → sheet with mandatory note.
- `report_found` creates the handover and OTP and marks the item `at_security` in one step.
- Owner gets a live in-app ping (Supabase Realtime) and My Posts / item detail update live.
- Admin home: tabs **With security** (with OTPs), **Lost**, **Returned**; OTP search box. A full code with no match says "don't hand anything over".
- Trace complete sheet: item photo, finder's note, owner's description, code check → `complete_handover` → item `returned`.

## 7. Notifications ✅
- `notifications` table filled by a trigger when an owner's item becomes "with security" or "returned" (never contains the code).
- Notifications tab with unread badge, mark read / mark all read, tap to open the item.
- Live ping comes from new notification rows (Realtime), so nothing is missed while the app was closed.
- Optional, not built: push notifications when the app is closed (needs Firebase + APNs).

## 8. Polish & Testing ✅
- Form validation, empty states, error snackbars.
- Unit tests for OTP flow and role access (Flutter: `test/`; database: `supabase/tests`).
- Manual test checklist covering the full owner → finder → admin → owner flow (`docs/TESTING.md`).
- README: setup, env variables, SQL migrations, email template, how to make an admin account.
