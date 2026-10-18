-- ==============================================================================
-- Root N Branch — Executable Schema & Capacity Logic Verification Test Suite
-- Test File: 001_schema_verification_test.sql
-- Description:
--   Executable verification test suite using PostgreSQL DO blocks and loud assertions.
--   Tests:
--     1. Customer Profile RLS & Role Escalation Protection
--     2. Cross-Customer Appointment Isolation (RLS Verification)
--     3. Server-Side Price & Duration Calculation & Instant Booking
--     4. Customer Appointment Identity Spoofing Rejection
--     5. Specialty Eligibility in Any Stylist Allocation
--     6. Staff Days-Off & Missing Weekday Rejection
--     7. Database Overlapping Double-Booking Rejection (GiST Exclusion)
--     8. Sequential Non-Overlapping Bookings Allowed
--     9. Outside Operating Hours & Midnight Crossing Rejection
--    10. Customer Modification Protections & Cancellation Workflow
--
-- Security Testing Methodology:
--   - Uses `SET LOCAL ROLE authenticated` to enforce real PostgreSQL Row Level Security
--     (RLS), ensuring tests do not bypass policies as superuser/postgres.
--   - Sets Supabase JWT claims (`request.jwt.claims`, `request.jwt.claim.sub`,
--     `request.jwt.claim.role`) to accurately simulate the client session context.
--   - Every exception block inspects SQLSTATE and SQLERRM so unexpected setup or syntax
--     errors fail loudly rather than being masked as false positives.
--
-- Rollback Guarantee:
--   The entire suite runs inside a single transaction block (BEGIN...ROLLBACK).
--   On completion, all test fixtures and state changes are 100% reverted.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 0. Seed Test Fixtures (Isolated within transaction)
-- ------------------------------------------------------------------------------

-- Seed Salon Profile
INSERT INTO public.salon (
  id, name, tagline, description, phone, email,
  address_line1, city, state, postal_code, timezone
) VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Root N Branch Men''s Salon Test',
  'Premium Grooming',
  'Test Salon Entity',
  '+91 99999 88888',
  'test@rootnbranch.com',
  '123 Salon St',
  'Bengaluru',
  'Karnataka',
  '560001',
  'Asia/Kolkata'
) ON CONFLICT (is_singleton) DO UPDATE
SET name = 'Root N Branch Men''s Salon Test';

-- Seed General Salon Opening Hours (Monday = 1 through Sunday = 0; open 09:00 - 21:00)
INSERT INTO public.working_hours (salon_id, staff_id, day_of_week, open_time, close_time, is_closed)
SELECT
  '11111111-1111-1111-1111-111111111111',
  NULL,
  d,
  '09:00'::TIME,
  '21:00'::TIME,
  false
FROM generate_series(0, 6) AS d
ON CONFLICT DO NOTHING;

-- Seed Services:
-- Service 1: Classic Haircut (Category: 'Hair', 30 min, Price: 450.00)
-- Service 2: Premium Beard Trim (Category: 'Beard', 45 min, Price: 600.00)
-- Service 3: Luxury Hair Coloring (Category: 'Color', 60 min, Price: 1500.00)
INSERT INTO public.services (
  id, salon_id, name, category, price, duration_minutes, is_active
) VALUES
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Classic Haircut', 'Hair', 450.00, 30, true),
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Premium Beard Trim', 'Beard', 600.00, 45, true),
  ('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 'Luxury Hair Coloring', 'Color', 1500.00, 60, true)
ON CONFLICT (id) DO NOTHING;

-- Seed Staff:
-- Stylist 1: Bob Barber (specialties: {'Hair', 'Beard'}) -> Has custom shifts Mon & Tue ONLY.
-- Stylist 2: Chloe Colorist (specialties: {'Color'}) -> Follows salon general hours (no custom shift rows).
-- Stylist 3: Dave Master (specialties: {}) -> All-rounder, follows salon general hours.
INSERT INTO public.staff (
  id, salon_id, full_name, title, specialties, is_active, display_order
) VALUES
  ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 'Bob Barber', 'Barber', ARRAY['Hair', 'Beard'], true, 1),
  ('66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'Chloe Colorist', 'Colorist', ARRAY['Color'], true, 2),
  ('77777777-7777-7777-7777-777777777777', '11111111-1111-1111-1111-111111111111', 'Dave Master', 'Master Stylist', ARRAY[]::TEXT[], true, 3)
ON CONFLICT (id) DO NOTHING;

-- Seed Bob Barber's custom shifts: ONLY Monday (day 1) and Tuesday (day 2) 09:00 - 17:00
-- Bob has NO entries for days 0, 3, 4, 5, 6 (meaning he is OFF-DUTY on those days)
INSERT INTO public.working_hours (salon_id, staff_id, day_of_week, open_time, close_time, is_closed)
VALUES
  ('11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 1, '09:00'::TIME, '17:00'::TIME, false),
  ('11111111-1111-1111-1111-111111111111', '55555555-5555-5555-5555-555555555555', 2, '09:00'::TIME, '17:00'::TIME, false)
ON CONFLICT DO NOTHING;

-- Seed Customer 1 in auth.users and public.profiles
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'customer1@example.com',
  'fake-hash',
  now(),
  '{"provider": "google", "providers": ["google"]}',
  '{"full_name": "Customer One"}',
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, full_name, role)
VALUES ('00000000-0000-0000-0000-000000000001', 'Customer One', 'customer')
ON CONFLICT (id) DO UPDATE SET full_name = 'Customer One', role = 'customer';

-- Seed Customer 2 in auth.users and public.profiles (for cross-user isolation tests)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'customer2@example.com',
  'fake-hash',
  now(),
  '{"provider": "google", "providers": ["google"]}',
  '{"full_name": "Customer Two"}',
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, full_name, role)
VALUES ('00000000-0000-0000-0000-000000000002', 'Customer Two', 'customer')
ON CONFLICT (id) DO UPDATE SET full_name = 'Customer Two', role = 'customer';

-- Seed Pre-Existing Appointment for Customer 2 (Dave Master, Monday 12:00 - 12:30)
INSERT INTO public.appointments (
  id, salon_id, customer_id, service_id, staff_id,
  start_time, end_time, service_price, status
) VALUES (
  '88888888-8888-8888-8888-888888888888',
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000002',
  '22222222-2222-2222-2222-222222222222',
  '77777777-7777-7777-7777-777777777777', -- Dave Master
  '2026-10-26 12:00:00+05:30',
  '2026-10-26 12:30:00+05:30',
  450.00,
  'confirmed'
) ON CONFLICT (id) DO NOTHING;

-- Grant required table privileges to standard Supabase application roles for testing
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Switch to the non-superuser authenticated role so PostgreSQL strictly enforces RLS policies
SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------------------
-- TEST 1: Customer Profile RLS & Role Escalation Protection
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_count INTEGER;
  v_rows_affected INTEGER;
  v_caught BOOLEAN := false;
  v_err_msg TEXT := '';
  v_err_code TEXT := '';
BEGIN
  -- Simulate Customer 1 authenticated session
  PERFORM set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);
  PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  -- 1A: Customer 1 can read own profile
  SELECT count(*) INTO v_count FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000001';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'TEST 1A FAILED: Customer 1 could not read their own profile!';
  END IF;

  -- 1B: Customer 1 CANNOT read Customer 2 profile (RLS isolates profiles)
  SELECT count(*) INTO v_count FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000002';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'TEST 1B FAILED: RLS leaked Customer 2 profile to Customer 1! (Count: %)', v_count;
  END IF;

  -- 1C: Customer 1 can update own profile details (full_name, phone)
  UPDATE public.profiles
  SET full_name = 'Customer One Updated', phone = '+91 99999 11111'
  WHERE id = '00000000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
  IF v_rows_affected <> 1 THEN
    RAISE EXCEPTION 'TEST 1C FAILED: Customer 1 could not update their own profile details!';
  END IF;

  -- 1D: Customer 1 CANNOT update Customer 2 profile (RLS hides the row)
  UPDATE public.profiles
  SET full_name = 'Hacked Name'
  WHERE id = '00000000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
  IF v_rows_affected <> 0 THEN
    RAISE EXCEPTION 'TEST 1D FAILED: Customer 1 updated Customer 2 profile!';
  END IF;

  -- 1E: Customer 1 CANNOT escalate their own role to owner
  BEGIN
    UPDATE public.profiles
    SET role = 'owner'
    WHERE id = '00000000-0000-0000-0000-000000000001';
  EXCEPTION WHEN OTHERS THEN
    v_caught := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 1E FAILED: Customer was able to escalate role to owner!';
  END IF;

  IF v_err_msg NOT LIKE '%You do not have permission to alter account roles%' THEN
    RAISE EXCEPTION 'TEST 1E FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  RAISE NOTICE 'TEST 1 PASSED: Profile RLS isolation and role escalation prevention verified.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 2: Cross-Customer Appointment Isolation (RLS Verification)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_count INTEGER;
  v_rows_affected INTEGER;
BEGIN
  -- Customer 1 session
  PERFORM set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);
  PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  -- 2A: Customer 1 CANNOT see Customer 2 appointment
  SELECT count(*) INTO v_count
  FROM public.appointments
  WHERE id = '88888888-8888-8888-8888-888888888888';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'TEST 2A FAILED: Customer 1 was able to read Customer 2 appointment! (RLS leak)';
  END IF;

  -- 2B: Customer 1 CANNOT update or cancel Customer 2 appointment
  UPDATE public.appointments
  SET status = 'cancelled'
  WHERE id = '88888888-8888-8888-8888-888888888888';
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

  IF v_rows_affected <> 0 THEN
    RAISE EXCEPTION 'TEST 2B FAILED: Customer 1 was able to update Customer 2 appointment!';
  END IF;

  -- 2C: Customer 1 CANNOT delete Customer 2 appointment
  DELETE FROM public.appointments
  WHERE id = '88888888-8888-8888-8888-888888888888';
  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

  IF v_rows_affected <> 0 THEN
    RAISE EXCEPTION 'TEST 2C FAILED: Customer 1 was able to delete Customer 2 appointment!';
  END IF;

  RAISE NOTICE 'TEST 2 PASSED: Cross-customer appointment isolation enforced by RLS.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 3: Server-Side Price & Duration Calculation & Instant Booking
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_appt public.appointments%ROWTYPE;
BEGIN
  -- Customer 1 session
  PERFORM set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);
  PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  -- Insert appointment with bogus client price (0.00), bogus 10-hour duration, and bogus status ('pending')
  -- Future Monday at 10:00 (Asia/Kolkata): 2026-10-26 10:00:00+05:30
  INSERT INTO public.appointments (
    salon_id, customer_id, service_id, staff_id,
    start_time, end_time, service_price, status
  ) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222', -- Classic Haircut (450.00, 30 min)
    NULL,                                    -- Any Stylist
    '2026-10-26 10:00:00+05:30',
    '2026-10-26 20:00:00+05:30',             -- Bogus 10 hours
    0.00,                                    -- Bogus price
    'pending'                                -- Bogus status
  ) RETURNING * INTO v_appt;

  IF v_appt.service_price <> 450.00 THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Client price was not overwritten! Expected 450.00, got %', v_appt.service_price;
  END IF;

  IF v_appt.end_time <> '2026-10-26 10:30:00+05:30'::TIMESTAMPTZ THEN
    RAISE EXCEPTION 'TEST 3 FAILED: End time was not calculated correctly! Expected 10:30, got %', v_appt.end_time;
  END IF;

  IF v_appt.status <> 'confirmed' THEN
    RAISE EXCEPTION 'TEST 3 FAILED: Instant booking status was not set to confirmed! Got %', v_appt.status;
  END IF;

  IF NOT v_appt.is_any_stylist THEN
    RAISE EXCEPTION 'TEST 3 FAILED: is_any_stylist flag was not set to true!';
  END IF;

  IF v_appt.customer_id <> '00000000-0000-0000-0000-000000000001' THEN
    RAISE EXCEPTION 'TEST 3 FAILED: customer_id does not match auth.uid()!';
  END IF;

  RAISE NOTICE 'TEST 3 PASSED: Price, duration, and instant confirmed status were enforced.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 4: Customer Appointment Identity Spoofing Rejection
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_appt public.appointments%ROWTYPE;
BEGIN
  -- Customer 1 session attempts to insert appointment with customer_id of Customer 2
  PERFORM set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-000000000001", "role": "authenticated"}', true);
  PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  INSERT INTO public.appointments (
    salon_id, customer_id, service_id, staff_id, start_time
  ) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000002', -- Spoofed Customer 2 ID
    '22222222-2222-2222-2222-222222222222',
    NULL,
    '2026-10-26 10:30:00+05:30'
  ) RETURNING * INTO v_appt;

  -- The BEFORE INSERT trigger MUST force NEW.customer_id to the authenticated auth.uid()
  IF v_appt.customer_id <> '00000000-0000-0000-0000-000000000001' THEN
    RAISE EXCEPTION 'TEST 4 FAILED: Identity spoofing succeeded! customer_id was not forced to auth.uid()!';
  END IF;

  RAISE NOTICE 'TEST 4 PASSED: Customer identity spoofing prevented; customer_id forced to auth.uid().';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 5: Specialty Eligibility in Any Stylist Allocation
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_appt public.appointments%ROWTYPE;
BEGIN
  -- Customer 1 books "Luxury Hair Coloring" (requires Color specialty) with Any Stylist on Monday 11:00
  -- Bob Barber only has {'Hair', 'Beard'} -> CANNOT be allocated
  -- Chloe Colorist has {'Color'} -> Qualified
  -- Dave Master has {} -> Qualified all-rounder
  INSERT INTO public.appointments (
    salon_id, customer_id, service_id, staff_id, start_time
  ) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    '44444444-4444-4444-4444-444444444444', -- Luxury Hair Coloring (60 min)
    NULL,                                    -- Any Stylist
    '2026-10-26 11:00:00+05:30'
  ) RETURNING * INTO v_appt;

  IF v_appt.staff_id = '55555555-5555-5555-5555-555555555555' THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Bob Barber was allocated for coloring despite lacking specialty!';
  END IF;

  IF v_appt.staff_id NOT IN ('66666666-6666-6666-6666-666666666666', '77777777-7777-7777-7777-777777777777') THEN
    RAISE EXCEPTION 'TEST 5 FAILED: Unexpected stylist allocated: %', v_appt.staff_id;
  END IF;

  RAISE NOTICE 'TEST 5 PASSED: Specialty matching allocated only qualified stylists.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 6: Staff Days-Off & Missing Weekday Rejection
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_caught BOOLEAN := false;
  v_err_msg TEXT := '';
  v_err_code TEXT := '';
BEGIN
  -- Bob Barber has custom shifts on Mon and Tue ONLY.
  -- Attempt to book Bob specifically on Wednesday: 2026-10-28 10:00:00+05:30
  BEGIN
    INSERT INTO public.appointments (
      salon_id, customer_id, service_id, staff_id, start_time
    ) VALUES (
      '11111111-1111-1111-1111-111111111111',
      '00000000-0000-0000-0000-000000000001',
      '22222222-2222-2222-2222-222222222222',
      '55555555-5555-5555-5555-555555555555', -- Bob Barber
      '2026-10-28 10:00:00+05:30'              -- Wednesday
    );
  EXCEPTION WHEN OTHERS THEN
    v_caught := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 6 FAILED: Stylist was booked on their scheduled day off!';
  END IF;

  IF v_err_msg NOT LIKE '%is not on duty during the requested time%' THEN
    RAISE EXCEPTION 'TEST 6 FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  RAISE NOTICE 'TEST 6 PASSED: Scheduled days off and missing weekday schedules are rejected.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 7: Overlapping Booking Rejection on the Same Stylist (GiST Exclusion)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_caught BOOLEAN := false;
  v_err_msg TEXT := '';
  v_err_code TEXT := '';
BEGIN
  -- Book Chloe Colorist specifically on Monday 14:00 - 15:00
  INSERT INTO public.appointments (
    salon_id, customer_id, service_id, staff_id, start_time
  ) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    '44444444-4444-4444-4444-444444444444', -- 60 min
    '66666666-6666-6666-6666-666666666666',
    '2026-10-26 14:00:00+05:30'
  );

  -- Attempt overlapping booking for Chloe from 14:30 - 15:30 (overlaps by 30 min)
  BEGIN
    INSERT INTO public.appointments (
      salon_id, customer_id, service_id, staff_id, start_time
    ) VALUES (
      '11111111-1111-1111-1111-111111111111',
      '00000000-0000-0000-0000-000000000001',
      '44444444-4444-4444-4444-444444444444',
      '66666666-6666-6666-6666-666666666666',
      '2026-10-26 14:30:00+05:30'
    );
  EXCEPTION WHEN OTHERS THEN
    v_caught := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 7 FAILED: Overlapping booking for the same stylist was allowed!';
  END IF;

  IF v_err_msg NOT LIKE '%is already booked during this time slot%'
     AND v_err_msg NOT LIKE '%conflicting key value violates exclusion constraint%' THEN
    RAISE EXCEPTION 'TEST 7 FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  RAISE NOTICE 'TEST 7 PASSED: Overlapping appointment for the same stylist was rejected.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 8: Sequential Non-Overlapping Bookings Allowed
-- ------------------------------------------------------------------------------
DO $$
BEGIN
  -- Book Chloe Colorist 15:00 - 16:00 (immediately following previous 14:00 - 15:00 booking)
  INSERT INTO public.appointments (
    salon_id, customer_id, service_id, staff_id, start_time
  ) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    '44444444-4444-4444-4444-444444444444',
    '66666666-6666-6666-6666-666666666666',
    '2026-10-26 15:00:00+05:30'
  );

  RAISE NOTICE 'TEST 8 PASSED: Back-to-back sequential appointments for the same stylist succeed.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 9: Outside Operating Hours & Midnight Crossing Rejection
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_caught_outside BOOLEAN := false;
  v_caught_midnight BOOLEAN := false;
  v_err_msg TEXT := '';
  v_err_code TEXT := '';
BEGIN
  -- Case A: Appointment extends past salon closing (closes at 21:00; booking at 20:45 with 30-min duration)
  BEGIN
    INSERT INTO public.appointments (
      salon_id, customer_id, service_id, staff_id, start_time
    ) VALUES (
      '11111111-1111-1111-1111-111111111111',
      '00000000-0000-0000-0000-000000000001',
      '22222222-2222-2222-2222-222222222222', -- 30 min -> ends at 21:15
      NULL,
      '2026-10-26 20:45:00+05:30'
    );
  EXCEPTION WHEN OTHERS THEN
    v_caught_outside := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught_outside THEN
    RAISE EXCEPTION 'TEST 9A FAILED: Appointment extending past closing time was allowed!';
  END IF;

  IF v_err_msg NOT LIKE '%falls outside salon operating hours%' THEN
    RAISE EXCEPTION 'TEST 9A FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  -- Case B: Appointment crosses midnight (starts 23:45 with 30-min duration -> ends 00:15 next day)
  BEGIN
    INSERT INTO public.appointments (
      salon_id, customer_id, service_id, staff_id, start_time
    ) VALUES (
      '11111111-1111-1111-1111-111111111111',
      '00000000-0000-0000-0000-000000000001',
      '22222222-2222-2222-2222-222222222222', -- 30 min
      NULL,
      '2026-10-26 23:45:00+05:30'
    );
  EXCEPTION WHEN OTHERS THEN
    v_caught_midnight := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught_midnight THEN
    RAISE EXCEPTION 'TEST 9B FAILED: Appointment crossing midnight was allowed!';
  END IF;

  IF v_err_msg NOT LIKE '%Appointments crossing local midnight%' THEN
    RAISE EXCEPTION 'TEST 9B FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  RAISE NOTICE 'TEST 9 PASSED: Appointments outside operating hours and crossing midnight are rejected.';
END $$;

-- ------------------------------------------------------------------------------
-- TEST 10: Customer Modification Protections & Cancellation Workflow
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_appt_id UUID;
  v_caught_price BOOLEAN := false;
  v_caught_status BOOLEAN := false;
  v_err_msg TEXT := '';
  v_err_code TEXT := '';
  v_final_status TEXT;
BEGIN
  -- Customer creates valid appointment
  INSERT INTO public.appointments (
    salon_id, customer_id, service_id, staff_id, start_time
  ) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    NULL,
    '2026-10-26 16:00:00+05:30'
  ) RETURNING id INTO v_appt_id;

  -- 10A: Customer attempts to tamper with service_price on update
  BEGIN
    UPDATE public.appointments
    SET service_price = 10.00
    WHERE id = v_appt_id;
  EXCEPTION WHEN OTHERS THEN
    v_caught_price := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught_price THEN
    RAISE EXCEPTION 'TEST 10A FAILED: Customer altered service_price on update!';
  END IF;

  IF v_err_msg NOT LIKE '%Protected booking fields%' THEN
    RAISE EXCEPTION 'TEST 10A FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  -- 10B: Customer attempts to change status to 'completed'
  BEGIN
    UPDATE public.appointments
    SET status = 'completed'
    WHERE id = v_appt_id;
  EXCEPTION WHEN OTHERS THEN
    v_caught_status := true;
    v_err_code := SQLSTATE;
    v_err_msg := SQLERRM;
  END;

  IF NOT v_caught_status THEN
    RAISE EXCEPTION 'TEST 10B FAILED: Customer marked appointment as completed!';
  END IF;

  IF v_err_msg NOT LIKE '%Customers may only change appointment status to cancelled%'
     AND v_err_msg NOT LIKE '%violates row-level security policy%' THEN
    RAISE EXCEPTION 'TEST 10B FAILED: Unexpected error caught [%]: %', v_err_code, v_err_msg;
  END IF;

  -- 10C: Valid customer action: Cancel own future appointment
  UPDATE public.appointments
  SET status = 'cancelled', cancellation_reason = 'Schedule conflict'
  WHERE id = v_appt_id;

  SELECT status INTO v_final_status FROM public.appointments WHERE id = v_appt_id;
  IF v_final_status <> 'cancelled' THEN
    RAISE EXCEPTION 'TEST 10C FAILED: Appointment status was not updated to cancelled! Got: %', v_final_status;
  END IF;

  RAISE NOTICE 'TEST 10 PASSED: Customer protected fields locked; status update restricted strictly to cancelled.';
END $$;

-- ------------------------------------------------------------------------------
-- Teardown: Reset Session Role & Rollback All Changes
-- ------------------------------------------------------------------------------
RESET ROLE;
ROLLBACK;
