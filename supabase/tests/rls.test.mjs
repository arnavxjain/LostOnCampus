// Database tests: runs every migration in supabase/migrations against an
// in-memory Postgres (PGlite) with minimal stand-ins for Supabase's auth and
// storage schemas, then checks the OTP flow and every RLS rule as different users.
//
//   cd supabase/tests && npm install && npm test

import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const migrationsDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'migrations');
const migrations = readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort();

const db = new PGlite({ extensions: { pgcrypto } });

// Stand-ins for what Supabase provides.
await db.exec(`
  create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
  grant usage on schema public to anon, authenticated, service_role;
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
  create schema extensions; grant usage on schema extensions to anon, authenticated, service_role;
  create schema auth; grant usage on schema auth to anon, authenticated, service_role;
  create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant execute on function auth.uid() to anon, authenticated, service_role;
  create schema storage; grant usage on schema storage to anon, authenticated, service_role;
  create table storage.buckets (id text primary key, name text, public bool, file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
  alter table storage.objects enable row level security;
  grant all on storage.objects to authenticated;
  create function storage.foldername(name text) returns text[] language sql immutable as
    $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1] $$;
  grant execute on function storage.foldername(text) to authenticated;
  create publication supabase_realtime;
`);

const U = {
  owner: '00000000-0000-0000-0000-00000000000a',
  finder: '00000000-0000-0000-0000-00000000000b',
  bystander: '00000000-0000-0000-0000-00000000000c',
  admin: '00000000-0000-0000-0000-000000000001',
  admin2: '00000000-0000-0000-0000-000000000002',
};

for (const file of migrations) {
  await db.exec(readFileSync(join(migrationsDir, file), 'utf8'));
  if (file === '20261018000000_init_schema.sql') {
    // Data as it existed before the admin flow (a floor guard and an item
    // mid-handover), to check that the next migration converts it cleanly.
    for (const [name, id] of Object.entries(U)) {
      await db.query(`insert into auth.users values ($1, $2, $3)`, [id, `${name}@x.com`, JSON.stringify({ full_name: name })]);
    }
    await db.exec(`
      insert into floors (name) values ('Floor 1');
      update profiles set role = 'guard', floor_id = 1 where id = '${U.admin}';
      insert into items (id, owner_id, title) values ('10000000-0000-0000-0000-000000000001', '${U.owner}', 'Old item');
      insert into handovers (item_id, finder_id, floor_id) values ('10000000-0000-0000-0000-000000000001', '${U.finder}', 1);
    `);
  }
}
console.log(`applied ${migrations.length} migrations: ${migrations.join(', ')}`);

// --- helpers ---------------------------------------------------------------

let failures = 0;

/** Runs [sql] as [user] through RLS (role `authenticated`, auth.uid() = user). */
async function as(user, sql, params = []) {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${user ?? ''}', false)`);
  await db.exec('set role authenticated');
  try { return await db.query(sql, params); } finally { await db.exec('reset role'); }
}

async function asAnon(sql, params = []) {
  await db.exec('set role anon');
  try { return await db.query(sql, params); } finally { await db.exec('reset role'); }
}

async function ok(label, fn, check = () => true) {
  try {
    const r = await fn();
    if (check(r)) console.log(`  ok    ${label}`);
    else { failures++; console.log(`  FAIL  ${label} -> unexpected ${JSON.stringify(r.rows)}`); }
  } catch (e) { failures++; console.log(`  FAIL  ${label} -> ${e.message}`); }
}

/** Passes if [fn] throws (optionally with [expectMsg]) or its result satisfies [check]. */
async function denied(label, fn, check, expectMsg) {
  try {
    const r = await fn();
    if (check && check(r)) console.log(`  ok    ${label} (nothing visible/affected)`);
    else { failures++; console.log(`  FAIL  ${label} -> was allowed: ${JSON.stringify(r.rows)}`); }
  } catch (e) {
    if (expectMsg && !e.message.includes(expectMsg)) { failures++; console.log(`  FAIL  ${label} -> wrong error: ${e.message}`); }
    else console.log(`  ok    ${label} (${e.message.split('\n')[0]})`);
  }
}

const none = (r) => r.rows.length === 0;
const count = (n) => (r) => r.rows.length === n;

// --- data migration --------------------------------------------------------

console.log('\ndata migration');
await ok('guard became admin', () => db.query(`select role from profiles where id = $1`, [U.admin]), (r) => r.rows[0].role === 'admin');
await ok('old handover got a note and at_security', () => db.query(`select note, status from handovers`),
  (r) => r.rows[0].note === 'Left at Floor 1 security' && r.rows[0].status === 'at_security');
await ok('floors table dropped', () => db.query(`select to_regclass('public.floors') as t`), (r) => r.rows[0].t === null);
await ok('items and notifications are in the realtime publication', () =>
  db.query(`select tablename from pg_publication_tables where pubname = 'supabase_realtime'`),
  (r) => ['items', 'notifications'].every((t) => r.rows.some((x) => x.tablename === t)));
await db.exec(`update profiles set role = 'admin' where id = '${U.admin2}'`);
await ok('an account becomes admin with a plain role update', () => db.query(`select role from profiles where id = $1`, [U.admin2]),
  (r) => r.rows[0].role === 'admin');

// --- profiles, storage, anon -----------------------------------------------

console.log('\nprofiles');
await ok('signup trigger creates a student profile', () => as(U.owner, `select full_name, role from profiles`),
  (r) => r.rows.length === 1 && r.rows[0].full_name === 'owner' && r.rows[0].role === 'student');
await ok('user can edit own name', () => as(U.owner, `update profiles set full_name = 'Owner O' where id = $1 returning id`, [U.owner]), count(1));
await denied('user cannot make themselves an admin', () => as(U.owner, `update profiles set role = 'admin' where id = $1`, [U.owner]));
await denied('user cannot read other profiles', () => as(U.owner, `select * from profiles where id = $1`, [U.finder]), none);
await denied('anon cannot read items', () => asAnon(`select * from items`));

console.log('\nstorage');
await ok('upload into own folder', () => as(U.owner, `insert into storage.objects (bucket_id, name) values ('item-images', $1)`, [`${U.owner}/a.jpg`]),
  (r) => r.affectedRows === 1);
await denied("upload into someone else's folder", () => as(U.owner, `insert into storage.objects (bucket_id, name) values ('item-images', $1)`, [`${U.finder}/a.jpg`]));
await ok('bucket is public', () => db.query(`select public from storage.buckets where id = 'item-images'`), (r) => r.rows[0].public === true);

// --- items -----------------------------------------------------------------

console.log('\nitems');
const item = (await as(U.owner, `insert into items (title, category) values ('Blue bottle', 'bottle') returning id, status, owner_id`)).rows[0];
await ok('owner posts item: lost, owned by them', async () => ({ rows: [item] }), () => item.status === 'lost' && item.owner_id === U.owner);
await denied('cannot post an item for someone else', () => as(U.owner, `insert into items (owner_id, title) values ($1, 'x')`, [U.finder]));
await denied('cannot post with a non-lost status', () => as(U.owner, `insert into items (title, status) values ('x', 'returned')`));
await denied('empty title rejected', () => as(U.owner, `insert into items (title) values ('   ')`));
await ok('other students see lost items', () => as(U.bystander, `select id from items where id = $1`, [item.id]), count(1));
await denied('non-owner cannot edit', () => as(U.finder, `update items set title = 'hacked' where id = $1 returning id`, [item.id]), none);
await denied('owner cannot change status directly', () => as(U.owner, `update items set status = 'returned' where id = $1`, [item.id]));
await ok('owner can delete while lost', async () => {
  const it = (await as(U.owner, `insert into items (title) values ('Keys') returning id`)).rows[0];
  return as(U.owner, `delete from items where id = $1 returning id`, [it.id]);
}, count(1));

// --- found flow ------------------------------------------------------------

console.log('\nreport_found');
await denied('owner cannot report own item', () => as(U.owner, `select report_found($1, 'Floor 2 desk')`, [item.id]), null, "can't report your own");
await denied('note is mandatory', () => as(U.finder, `select report_found($1, '  ')`, [item.id]), null, 'Add a note');
await denied('finder cannot insert handovers directly', () => as(U.finder, `insert into handovers (item_id, note) values ($1, 'x desk')`, [item.id]));
await denied('anon cannot call report_found', () => asAnon(`select report_found($1, 'x desk')`, [item.id]), null, 'permission denied');
const ho = (await as(U.finder, `select report_found($1, 'Left with Floor 2 security') as id`, [item.id])).rows[0].id;
await ok('finder reports found', async () => ({ rows: [ho] }), () => !!ho);
await ok('item is with security straight away', () => db.query(`select status from items where id = $1`, [item.id]), (r) => r.rows[0].status === 'at_security');
await ok('a 6-digit active code exists', () => db.query(`select code, active from handover_codes where handover_id = $1`, [ho]),
  (r) => /^\d{6}$/.test(r.rows[0].code) && r.rows[0].active === true);
await denied('cannot report the same item twice', () => as(U.bystander, `select report_found($1, 'Floor 3 desk')`, [item.id]), null, 'already been found');
await denied('owner cannot delete once found', () => as(U.owner, `delete from items where id = $1 returning id`, [item.id]), none);
const code = (await db.query(`select code from handover_codes where handover_id = $1`, [ho])).rows[0].code;

console.log('\nwho sees the code');
await ok('owner sees code and note', () => as(U.owner, `select c.code, h.note from handover_codes c join handovers h on h.id = c.handover_id where h.id = $1`, [ho]),
  (r) => r.rows[0]?.code === code && r.rows[0]?.note === 'Left with Floor 2 security');
await ok('admin sees code', () => as(U.admin, `select code from handover_codes where handover_id = $1`, [ho]), count(1));
await ok('every admin sees code', () => as(U.admin2, `select code from handover_codes where handover_id = $1`, [ho]), count(1));
await ok('admin sees every item, lost and with security', async () => {
  await as(U.owner, `insert into items (title) values ('Still lost')`);
  return as(U.admin, `select status from items`);
}, (r) => r.rows.some((x) => x.status === 'lost') && r.rows.some((x) => x.status === 'at_security'));
await denied('FINDER cannot see the code', () => as(U.finder, `select * from handover_codes`), none);
await ok('finder still sees the item and note', () => as(U.finder, `select h.note from items i join handovers h on h.item_id = i.id where i.id = $1`, [item.id]), count(1));
await denied('bystander no longer sees the item', () => as(U.bystander, `select id from items where id = $1`, [item.id]), none);
await denied('bystander cannot see codes', () => as(U.bystander, `select * from handover_codes`), none);
await denied('admin cannot edit items', () => as(U.admin, `update items set title = 'x' where id = $1 returning id`, [item.id]), none);

// --- notifications ---------------------------------------------------------

console.log('\nnotifications');
await ok('owner got item_found with the finder note', () => as(U.owner, `select type, body, read_at from notifications where item_id = $1`, [item.id]),
  (r) => r.rows.length === 1 && r.rows[0].type === 'item_found' && r.rows[0].body.includes('Left with Floor 2 security') && r.rows[0].read_at === null);
await ok('the code is never in a notification', () => db.query(`select body from notifications`), (r) => r.rows.every((x) => !x.body.includes(code)));
await denied('finder cannot see owner notifications', () => as(U.finder, `select * from notifications`), none);
await denied('admin cannot see owner notifications', () => as(U.admin, `select * from notifications`), none);
await denied('users cannot create notifications', () => as(U.owner, `insert into notifications (user_id, type, title, body) values ($1, 'item_found', 'x', 'y')`, [U.owner]));
await denied('users cannot rewrite notification text', () => as(U.owner, `update notifications set title = 'hacked'`));
await ok('owner marks it read', () => as(U.owner, `update notifications set read_at = now() where item_id = $1 returning id`, [item.id]), count(1));
await denied('others cannot mark it', () => as(U.finder, `update notifications set read_at = null returning id`), none);
await ok('title edits do not notify', async () => {
  const it = (await as(U.owner, `insert into items (title) values ('Pen') returning id`)).rows[0];
  await as(U.owner, `update items set title = 'Blue pen' where id = $1`, [it.id]);
  return as(U.owner, `select * from notifications where item_id = $1`, [it.id]);
}, none);

// --- trace complete --------------------------------------------------------

console.log('\ncomplete_handover');
const wrong = code === '000000' ? '111111' : '000000';
await denied('students cannot complete', () => as(U.owner, `select complete_handover($1, $2)`, [ho, code]), null, 'Only security staff');
await denied('wrong code is rejected', () => as(U.admin, `select complete_handover($1, $2)`, [ho, wrong]), null, "doesn't match");
await ok('admin completes with the right code', () => as(U.admin, `select complete_handover($1, $2)`, [ho, code]));
await ok('item returned, handover collected, code retired', () => db.query(
  `select i.status as i, h.status as h, h.completed_by, c.active from items i join handovers h on h.item_id = i.id
   join handover_codes c on c.handover_id = h.id where h.id = $1`, [ho]),
  (r) => r.rows[0].i === 'returned' && r.rows[0].h === 'collected' && r.rows[0].completed_by === U.admin && r.rows[0].active === false);
await denied('cannot complete twice', () => as(U.admin, `select complete_handover($1, $2)`, [ho, code]), null, "doesn't match");
await ok('owner got item_collected', () => as(U.owner, `select type from notifications where item_id = $1 order by created_at`, [item.id]),
  (r) => r.rows.length === 2 && r.rows[1].type === 'item_collected');

// --- code uniqueness -------------------------------------------------------

console.log('\ncode uniqueness');
await ok('100 items at security all get distinct codes', async () => {
  for (let i = 0; i < 100; i++) {
    const id = (await as(U.owner, `insert into items (title) values ('bulk ${i}') returning id`)).rows[0].id;
    await as(U.finder, `select report_found($1, 'Ground floor desk')`, [id]);
  }
  return db.query(`select count(*)::int as n, count(distinct code)::int as d from handover_codes where active`);
}, (r) => r.rows[0].n === r.rows[0].d && r.rows[0].n >= 100);

console.log(failures ? `\n${failures} FAILED` : '\nall checks passed');
process.exit(failures ? 1 : 0);
