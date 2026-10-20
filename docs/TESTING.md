# Manual test checklist

Run before a release or after changing a migration. Use **two simulators** (or a simulator and a phone) so the owner sees live updates while another account acts.

**Accounts needed**

| Account | Role | Used for |
|---|---|---|
| Owner | student | posts the item, receives the code |
| Finder | student | reports the item found |
| Security | admin (see README) | completes the trace |

Automated checks first: `flutter analyze`, `flutter test`, and `cd supabase/tests && npm test` should all pass.

## 1. Sign-up and login

- [ ] Register with an empty form: every field shows an error.
- [ ] Phone without a country code (`9876543210`): "Include country code".
- [ ] Mismatched passwords: "Passwords do not match".
- [ ] Valid registration → **Verify email** screen, Resend greyed out with a 60 s countdown.
- [ ] Wrong code: "That code is wrong or has expired…".
- [ ] Correct code from the email → Student home.
- [ ] Sign out → Login. Wrong password: "Incorrect email or password".
- [ ] Register, close the app before entering the code, then log in: taken to Verify email; Resend works immediately.
- [ ] Kill and reopen the app while signed in: stays signed in.
- [ ] Airplane mode, then log in: "Network error…" (not a generic error).

## 2. Posting (owner)

- [ ] **Post lost item** with no title / no category: field errors.
- [ ] Add a photo from the library, remove it, add it again.
- [ ] "Take photo" on a simulator: "Camera not available on this device".
- [ ] Type a title then swipe back: "Discard this post?". Keep editing keeps the text; Discard closes.
- [ ] Post with photo: snackbar, appears at the top of **Lost items** and in **My posts** as *Lost*.
- [ ] Post without photo: category icon shown instead.

## 3. Feed and search (any student)

- [ ] Search part of a title or description: list narrows as you type.
- [ ] Category chip with no matches: "No matching items".
- [ ] Clear search (×) and pick **All**: full list back.
- [ ] Pull to refresh works on an empty list too.
- [ ] Open another student's item: no delete button, **I Found This** shown.
- [ ] Open your own item: delete button shown, no **I Found This**.

## 4. Found flow (finder → owner)

Owner: stay on **Notifications** or **My posts**.

- [ ] Finder taps **I Found This**, submits an empty note: "Add a note so the owner knows where to go".
- [ ] Finder submits "Left with Floor 2 security": thank-you snackbar.
- [ ] Owner gets a live ping within seconds, with a **View** button.
- [ ] Owner's Notifications tab shows a **1** badge; the notification includes the finder's note and **no code**.
- [ ] Owner's post shows **With security**, the note, and the 6-digit code.
- [ ] Finder reopens the item: sees the note, **no code**, no Found button.
- [ ] A third student no longer sees the item in the feed.
- [ ] Owner can no longer delete the item.
- [ ] Close the owner's app, report another item found, reopen: unread notification waiting.

## 5. Security desk (admin)

- [ ] Log in as admin → **Security desk** with tabs *With security*, *Lost*, *Returned*. No student tabs.
- [ ] The found item is under *With security* with the same code the owner sees.
- [ ] Type the first 3 digits: list narrows.
- [ ] Type a wrong full code: "No item matches… Don't hand anything over."
- [ ] Type the owner's code: the item is highlighted; tap it.
- [ ] Sheet shows photo, finder's note and owner's description. Wrong code in the sheet: **Trace complete** stays disabled.
- [ ] Correct code → **Trace complete** → snackbar; item moves to *Returned* with the code struck through.
- [ ] Type the same code again: "This code was already used".
- [ ] While the admin screen is open, a finder reports another item: it appears without refreshing.
- [ ] Tap a *Lost* item: read-only detail, no Found or delete buttons.

## 6. After collection (owner)

- [ ] Owner gets an "Item collected" ping and notification.
- [ ] Post shows **Returned**.
- [ ] **Mark all read** clears the badge; tapping a notification opens its item.

## 7. Access checks

- [ ] A student cannot reach the admin screen (no way in the UI; role only changes in the database).
- [ ] An admin signing in is never shown student tabs.
- [ ] Changing a profile's role in Supabase takes effect after the user signs out and back in.
