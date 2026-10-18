# Root N Branch — Supabase Database Architecture & Migration Guide

> [!WARNING]
> **DEPLOYMENT STATUS: NOT DEPLOYED**
> This database schema and migration script have **NOT** been applied or executed against your live Supabase project. No database tables, triggers, or functions have been deployed. All application and database modifications remain strictly local.

---

## 📁 Migration & Test Files

- **[`supabase/migrations/001_initial_schema.sql`](file:///c:/Users/Acer/Documents/Root%20n%20Branch/supabase/migrations/001_initial_schema.sql)**:
  Core PostgreSQL migration establishing relational tables, Row Level Security (RLS) policies, GiST exclusion constraints, server-side pricing/duration enforcement, midnight-boundary validation, dynamic "Any Stylist" load-balanced allocation, and an idempotent backfill for existing Google Sign-In users.
- **[`supabase/tests/001_schema_verification_test.sql`](file:///c:/Users/Acer/Documents/Root%20n%20Branch/supabase/tests/001_schema_verification_test.sql)**:
  Self-contained executable verification test suite running 10 test blocks under `SET LOCAL ROLE authenticated` with simulated Supabase JWT session claims inside an isolated `BEGIN...ROLLBACK` transaction.

---

## 🏗️ Relational Schema Overview

| Table | Primary / Foreign Keys | Access Control & RLS | Purpose |
| :--- | :--- | :--- | :--- |
| **`public.profiles`** | `id UUID` -> `auth.users(id)` | Customers read/update own record. Role escalation blocked. Admins full access. | User metadata, contact info, and assigned role (`customer`, `staff`, `owner`, `admin`). |
| **`public.salon`** | `id UUID` (Singleton check) | Public read. Owner/Admin manage. | Root N Branch single salon entity, contacts, branding, and timezone. |
| **`public.services`** | `id UUID`, `salon_id UUID` | Public read active (`is_active = true`). Owner/Admin manage. | Catalog of services with exact `NUMERIC(10, 2)` pricing and duration in minutes. |
| **`public.staff`** | `id UUID`, `salon_id UUID`, opt `user_id` | Public read active (`is_active = true`). Owner/Admin manage. | Stylists, barbers, bio, avatar, and specialties array (`specialties TEXT[]`). |
| **`public.working_hours`** | `id UUID`, `salon_id UUID`, opt `staff_id` | Public read active hours. Owner/Admin manage. | Weekly operating schedule for salon (`staff_id IS NULL`) or individual staff shifts. |
| **`public.appointments`** | `id UUID`, `customer_id`, `service_id`, `staff_id` | Customers read/create/cancel own. Staff read assigned. Admins full access. | Customer appointments with `TIMESTAMPTZ` timestamps, pricing snapshot, and `is_any_stylist` flag. |

---

## 🔐 Google Auth Compatibility & Existing User Backfill

Your existing Supabase project is already configured for Google Sign-In. This migration is designed to preserve your authentication settings without disruption:

1. **Zero Modifications to Auth Config**:
   - The migration does **NOT** alter Supabase GoTrue configurations, Google OAuth credentials, redirect URIs, or token settings.
2. **Automated Provisioning for Future Users**:
   - The `trg_on_auth_user_created` trigger automatically provisions a `public.profiles` row whenever a new customer signs in via Google or email in the future, assigning the default role `'customer'`.
3. **Idempotent Backfill for Existing Users**:
   - For users who already authenticated with Google prior to running this migration, the migration executes an idempotent backfill immediately after table creation:
     ```sql
     INSERT INTO public.profiles (id, full_name, role)
     SELECT
       id,
       COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', ''),
       'customer'
     FROM auth.users
     ON CONFLICT (id) DO NOTHING;
     ```
   - **Safety Guarantees**:
     - `ON CONFLICT (id) DO NOTHING` guarantees existing data is never overwritten.
     - Role elevation is never performed; all existing accounts default to `'customer'`.
     - Ensures all existing user IDs satisfy the foreign key constraint `appointments.customer_id REFERENCES public.profiles(id)` without manual data intervention.

---

## ⚡ Instant Booking & Appointment Workflow

Root N Branch operates on an **Instant Booking** model:
1. **Creation**:
   - Customers initiate a booking by supplying `service_id`, `start_time`, and an optional `staff_id` (passing `staff_id = NULL` chooses **"Any Stylist"**).
   - The database trigger `trg_enforce_appointment_booking_rules` automatically:
     - Derives `customer_id` from the caller's verified `auth.uid()` (preventing identity spoofing).
     - Validates that the requested service is active.
     - Overwrites `service_price` with the catalog price from `public.services` (client-supplied prices are strictly ignored).
     - Automatically calculates `end_time` as: `start_time + (duration_minutes * interval '1 minute')`.
     - Enforces local calendar day boundaries: appointments crossing local midnight or extending past closing time are rejected.
     - Sets `status` to `'confirmed'`. Customers cannot select arbitrary statuses.
     - Allocates a verified, qualified, on-duty stylist if "Any Stylist" was chosen.
2. **Cancellation**:
   - Customers can cancel their own upcoming appointments via `UPDATE` (status set to `'cancelled'`).
   - The trigger `trg_restrict_customer_appointment_update` guarantees that customers cannot alter protected booking attributes (`service_id`, `service_price`, `start_time`, `end_time`, `staff_id`, `is_any_stylist`) or modify past/completed appointments.

---

## 📅 Staff Schedule & Days-Off Configuration Rules

Staff availability is determined by the unified database function `public.is_staff_on_duty`:

1. **Salon Opening Hours (`staff_id IS NULL`)**:
   - Defines standard business hours for each weekday (0 = Sunday through 6 = Saturday).
   - If no row exists for a day or `is_closed = true`, the salon is closed.
2. **Staff Custom Schedules (`staff_id IS NOT NULL`)**:
   - If a stylist has **at least one** shift row in `public.working_hours`:
     - They follow a custom schedule.
     - They are considered on duty **only** on days where an explicit row exists with `is_closed = false`, `open_time <= start_time`, and `close_time >= end_time`.
     - **Missing weekday rows mean the stylist is OFF-DUTY** on those days.
   - If a stylist has **zero** shift rows in `public.working_hours`:
     - They default to standard salon opening hours.

---

## 🛡️ "Any Stylist" Dynamic Allocation & Capacity Architecture

To eliminate the flaws of approximate unassigned capacity counters (such as false rejections from sequential shorter appointments or specialty mismatches), Root N Branch implements **Dynamic Stylist Allocation** at booking time:

1. **Transaction Serialization**:
   - At the beginning of the booking trigger, `PERFORM id FROM public.salon WHERE id = NEW.salon_id FOR UPDATE;` locks the canonical salon record.
   - This serializes concurrent booking requests for the salon, completely eliminating race conditions.
2. **Eligibility & Conflict Verification**:
   - When a customer selects "Any Stylist" (`staff_id IS NULL`), the database searches for an active stylist who:
     - Is marked `is_active = true`.
     - Is qualified to perform the service (the stylist's `specialties` array contains the service category or name, or `specialties` is empty, indicating an all-rounder).
     - Is scheduled on duty via `public.is_staff_on_duty(...)`.
     - Has **no** overlapping confirmed/pending appointment during `[start_time, end_time)`.
3. **Allocation & Load Balancing**:
   - If multiple eligible stylists are available, the trigger allocates the stylist with the fewest appointments on that date to ensure balanced workloads across the team.
   - Sets `NEW.staff_id := v_allocated_staff_id` and records `NEW.is_any_stylist := true`.
   - If no qualified stylist is free, the booking is rejected immediately with:
     `'No available stylist with the required specialty is on duty for the requested time slot.'`
4. **Hardware-Level Non-Overlap Protection**:
   - Because every customer booking is assigned a concrete stylist, PostgreSQL's `btree_gist` exclusion constraint:
     ```sql
     EXCLUDE USING gist (
       staff_id WITH =,
       (tstzrange(start_time, end_time, '[)')) WITH &&
     )
     ```
     actively and mathematically guarantees zero overlapping bookings for every stylist across the entire appointment duration.

---

## 🧪 Testing Architecture: Executable SQL vs. Client Session Verification

### What the SQL Test Suite Executes (`supabase/tests/001_schema_verification_test.sql`):
- **Real Row Level Security (RLS)**:
  - The script executes `SET LOCAL ROLE authenticated;`, switching PostgreSQL from the privileged table owner/superuser role to the unprivileged `authenticated` role.
  - This ensures PostgreSQL actually evaluates `USING` and `WITH CHECK` clauses rather than bypassing them.
- **Simulated JWT Claims**:
  - The test populates `request.jwt.claims` (JSON payload with `sub`, `role`, and `email`), `request.jwt.claim.sub`, and `request.jwt.claim.role`.
  - This provides identical context to what Supabase's PostgREST gateway passes to `auth.uid()` and `auth.role()`.
- **Cross-Customer Data Isolation**:
  - Verifies that Customer 1 cannot see Customer 2's profile or appointments (`count(*) = 0`).
  - Verifies that Customer 1 cannot mutate or cancel Customer 2's appointments (`ROW_COUNT = 0`).
- **Trigger Integrity & Tampering Protection**:
  - Verifies role escalation rejection (`role = 'owner'`).
  - Verifies service price and duration overrides.
  - Verifies identity spoofing prevention (`customer_id` forced to `auth.uid()`).
  - Verifies staff specialty matching during Any Stylist allocation.
  - Verifies staff days-off rejection.
  - Verifies GiST double-booking collision rejection.
  - Verifies back-to-back sequential booking support.
  - Verifies midnight crossing and closing time boundary enforcement.
  - Verifies that customers cannot modify protected booking attributes or set statuses other than `cancelled`.
- **Loud Assertions & Error Discrimination**:
  - Every exception block checks both `SQLSTATE` and `SQLERRM` so unexpected syntax or schema errors fail immediately rather than being masked as false passes.

### What Requires a Real Authenticated Client Session (End-to-End Testing):
The SQL test script exercises database-internal behavior. The following components cannot be validated within the SQL Editor alone and require testing through the Flutter application:
1. **Network & PostgREST HTTP Gateway**:
   - Validating that PostgREST correctly parses HTTP query parameters and headers into SQL queries.
2. **Cryptographic JWT Signature Verification**:
   - Validating that Supabase GoTrue issues valid HMAC/RSA signatures and that expired or tampered tokens are rejected before reaching PostgreSQL.
3. **Google Sign-In OAuth Flow**:
   - Verifying Google redirect URIs, OAuth token exchange, and automatic profile creation via client SDK.
4. **Client-Side State Management**:
   - Verifying Flutter error handling, optimistic UI updates, and reactive appointment streams.

---

## 🚀 Exact Recommended Execution Order for Development

To validate and deploy this schema safely without risking production data or interrupting Google Sign-In:

### Step 1: Provision a Dedicated Development Project
- Create a dedicated development project on Supabase (e.g. `root-n-branch-dev`).
- Do **NOT** apply new schema migrations directly to your production project until verified.

### Step 2: Apply Initial Schema Migration
- Open the development project dashboard > **SQL Editor > New query**.
- Copy and run [`supabase/migrations/001_initial_schema.sql`](file:///c:/Users/Acer/Documents/Root%20n%20Branch/supabase/migrations/001_initial_schema.sql).
- Verify that all 6 tables (`profiles`, `salon`, `services`, `staff`, `working_hours`, `appointments`) are created with RLS enabled.

### Step 3: Run the Schema Verification Test Suite
- Open **SQL Editor > New query**.
- Copy and run [`supabase/tests/001_schema_verification_test.sql`](file:///c:/Users/Acer/Documents/Root%20n%20Branch/supabase/tests/001_schema_verification_test.sql).
- Look for 10 `NOTICE: TEST X PASSED` log messages in the results console.
- Confirm the script terminates with `ROLLBACK`, leaving zero test artifacts in your dev database.

### Step 4: Seed Development Catalog Data
In the development project SQL Editor, insert initial operational data:
1. **Seed Singleton Salon Entity (Development Sample Data)**:

   > [!WARNING]
   > **DEVELOPMENT PLACEHOLDER WARNING — NOT PRODUCTION DATA**
   > The salon details below (name, phone, email, address, city, state, postal code, and timezone) are **placeholders for development and testing only**.
   > - They **must be replaced** with the actual, verified Root N Branch business details before deploying or using in production.
   > - This sample data must **not** be mistaken for real or verified salon business information.

   ```sql
   -- DEVELOPMENT SAMPLE DATA ONLY — Replace with verified salon business details before production
   INSERT INTO public.salon (
     name, tagline, description, phone, email,
     address_line1, city, state, postal_code, timezone
   ) VALUES (
     'Root N Branch Men''s Salon',
     'Premium Grooming & Styling',
     'Premier hair, beard, and grooming treatments for men.',
     '+91 98765 43210',
     'contact@rootnbranch.com',
     '123 Main High Street',
     'Bengaluru',
     'Karnataka',
     '560001',
     'Asia/Kolkata'
   );
   ```
2. **Seed Salon Operating Hours**:
   ```sql
   INSERT INTO public.working_hours (salon_id, staff_id, day_of_week, open_time, close_time, is_closed)
   SELECT
     (SELECT id FROM public.salon LIMIT 1),
     NULL,
     d,
     '09:00'::TIME,
     '21:00'::TIME,
     false
   FROM generate_series(0, 6) AS d;
   ```
3. **Seed Initial Services & Staff**:
   - Add active services to `public.services`.
   - Add active stylists to `public.staff` with their specialties.

### Step 5: Designate Salon Owner Account
Sign up through the Flutter app using Google Sign-In on the development project, then elevate your account role in the SQL Editor:
```sql
UPDATE public.profiles
SET role = 'owner'
WHERE id = (SELECT id FROM auth.users WHERE email = 'your-owner-email@example.com');
```

### Step 6: Test Flutter Application Integration
- Point the Flutter app (`SUPABASE_URL` and `SUPABASE_ANON_KEY`) to the development project.
- Verify Google Sign-In profile generation.
- Book appointments (both specific stylist and Any Stylist).
- Verify instant confirmation and customer cancellation flows.
