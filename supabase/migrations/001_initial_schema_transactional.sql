BEGIN;

-- ==============================================================================
-- Root N Branch — Initial Database Schema Migration
-- Migration: 001_initial_schema.sql
-- Description:
--   Establishes core relational data models, role-based access control (RBAC),
--   Row Level Security (RLS) policies, atomic capacity & concurrency controls,
--   and integrity constraints for Root N Branch (single-salon booking app).
--
-- Tables:
--   1. public.profiles       - Auth user metadata, contact info, and assigned role.
--   2. public.salon          - Singleton salon profile, branding, contact, and timezone.
--   3. public.services       - Salon service offerings, descriptions, prices, durations.
--   4. public.staff          - Stylist/staff profiles, bio, specialties, active status.
--   5. public.working_hours  - Weekly opening/closing schedule for salon and staff shifts.
--   6. public.appointments   - Customer bookings, pricing snapshot, times, and statuses.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. PostgreSQL Extensions & Prerequisites
-- ------------------------------------------------------------------------------

-- "pgcrypto" for gen_random_uuid() cryptographic IDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- "btree_gist" enables GiST indexes on scalar types (UUID, timestamps),
-- required for exclusion constraints preventing overlapping appointments.
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ------------------------------------------------------------------------------
-- 1. Helper Functions & Triggers
-- ------------------------------------------------------------------------------

-- Generic timestamp updater for updated_at columns
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. Profiles Table (1:1 with auth.users)
-- ------------------------------------------------------------------------------
-- Stores customer and staff profile data tied directly to Supabase Auth users.
-- Critical Security Rules:
--   - Default role is 'customer'.
--   - Privilege escalation is blocked via trigger `prevent_role_escalation`.
--   - Direct public self-registration via `handle_new_auth_user` forces role 'customer'.

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'staff', 'owner', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'User profiles extending Supabase auth.users with salon-specific roles.';
COMMENT ON COLUMN public.profiles.role IS 'Role hierarchy: customer (default), staff, owner, admin. Non-customers must be promoted by an owner/admin.';

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- Security Helper Function: Checks if current authenticated caller is an admin or salon owner.
-- SECURITY DEFINER with locked search_path ensures safe evaluation without search path hijacking.
CREATE OR REPLACE FUNCTION public.is_admin_or_owner(lookup_uid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = lookup_uid AND role IN ('owner', 'admin')
  );
$$;

-- Security Trigger: Prevent customers or staff from altering their own role or other users' roles
-- unless the caller is already a verified owner or administrator.
CREATE OR REPLACE FUNCTION public.prevent_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    -- Only an existing owner or admin (or service role execution) may modify roles
    IF auth.uid() IS NOT NULL AND NOT public.is_admin_or_owner(auth.uid()) THEN
      RAISE EXCEPTION 'Access Denied: You do not have permission to alter account roles.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prevent_role_escalation
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.prevent_role_escalation();

-- Trigger Function: Automatically provisions a profile when a new user signs up in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    ),
    'customer' -- ALWAYS force 'customer' for public self-registration
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- ------------------------------------------------------------------------------
-- 2.1 Backfill Existing Auth Users into public.profiles
-- ------------------------------------------------------------------------------
-- For users who signed up before this migration was applied (e.g. via Google Sign-In),
-- ensure a corresponding profile exists with default 'customer' role.
-- Idempotent: ON CONFLICT (id) DO NOTHING ensures existing profiles and non-customer
-- roles (such as manually promoted owners/admins) are never overwritten or altered.
INSERT INTO public.profiles (id, full_name, role)
SELECT
  id,
  COALESCE(
    raw_user_meta_data->>'full_name',
    raw_user_meta_data->>'name',
    ''
  ),
  'customer'
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 3. Salon Table (Singleton Salon Profile)
-- ------------------------------------------------------------------------------
-- Represents Root N Branch. A singleton check constraint guarantees exactly
-- one canonical salon record in the system.

CREATE TABLE IF NOT EXISTS public.salon (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  tagline TEXT,
  description TEXT,
  phone TEXT NOT NULL,
  email TEXT,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'India',
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  logo_url TEXT,
  banner_url TEXT,
  is_singleton BOOLEAN NOT NULL DEFAULT true UNIQUE CHECK (is_singleton = true),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.salon IS 'Root N Branch single salon metadata, contact details, branding, and timezone.';
COMMENT ON CONSTRAINT salon_is_singleton_check ON public.salon IS 'Enforces a single salon entity across the application.';

CREATE TRIGGER trg_salon_updated_at
BEFORE UPDATE ON public.salon
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ------------------------------------------------------------------------------
-- 4. Services Table
-- ------------------------------------------------------------------------------
-- Catalog of hair, beard, styling, and grooming services.
-- Prices use NUMERIC(10, 2) to prevent floating-point rounding discrepancies.

CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salon(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.services IS 'Salon service catalog with duration in minutes and exact numeric pricing.';

CREATE INDEX IF NOT EXISTS idx_services_salon_active ON public.services(salon_id, is_active);
CREATE INDEX IF NOT EXISTS idx_services_category ON public.services(category);

CREATE TRIGGER trg_services_updated_at
BEFORE UPDATE ON public.services
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ------------------------------------------------------------------------------
-- 5. Staff Table
-- ------------------------------------------------------------------------------
-- Stylists, barbers, and technicians working at the salon.

CREATE TABLE IF NOT EXISTS public.staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salon(id) ON DELETE CASCADE,
  user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  title TEXT NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  specialties TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.staff IS 'Salon stylist/staff profiles and credentials. Optionally linked to a user profile.';
COMMENT ON COLUMN public.staff.specialties IS 'Array of service names or categories the stylist specializes in. If empty, stylist performs all active services.';

CREATE INDEX IF NOT EXISTS idx_staff_salon_active ON public.staff(salon_id, is_active);

CREATE TRIGGER trg_staff_updated_at
BEFORE UPDATE ON public.staff
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ------------------------------------------------------------------------------
-- 6. Working Hours Table
-- ------------------------------------------------------------------------------
-- Opening and closing hours.
-- If staff_id is NULL -> Salon-level operating hours for that day.
-- If staff_id is NOT NULL -> Specific staff member's working shift for that day.
-- Staff Schedule Model:
--   - If a staff member has ANY shift rows in working_hours, they follow a custom schedule.
--     On any weekday with no row or is_closed = true, the stylist is OFF-DUTY.
--   - If a staff member has NO rows in working_hours, they follow general salon hours.
-- day_of_week: 0 = Sunday, 1 = Monday, 2 = Tuesday, 3 = Wednesday, 4 = Thursday, 5 = Friday, 6 = Saturday.

CREATE TABLE IF NOT EXISTS public.working_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salon(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES public.staff(id) ON DELETE CASCADE,
  day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  open_time TIME NOT NULL,
  close_time TIME NOT NULL,
  is_closed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_valid_hours CHECK (is_closed = true OR open_time < close_time)
);

COMMENT ON TABLE public.working_hours IS 'Weekly operational hours for the salon (staff_id IS NULL) or individual stylist shifts.';
COMMENT ON COLUMN public.working_hours.day_of_week IS 'Day of week index: 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday.';

-- Ensure unique schedule per day per salon / staff member
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_salon_hours
ON public.working_hours (salon_id, day_of_week)
WHERE staff_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_staff_hours
ON public.working_hours (salon_id, staff_id, day_of_week)
WHERE staff_id IS NOT NULL;

CREATE TRIGGER trg_working_hours_updated_at
BEFORE UPDATE ON public.working_hours
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ------------------------------------------------------------------------------
-- 6.1 Unified Staff Availability Evaluation Helper Function
-- ------------------------------------------------------------------------------
-- Evaluates whether a specific stylist is scheduled on duty for a given day and time:
--   1. If stylist has custom shifts in working_hours:
--      Must have an explicit row for p_dow with is_closed = false covering the window.
--      Absence of a row for that day means the stylist is OFF-DUTY.
--   2. If stylist has NO custom shifts in working_hours:
--      Defaults to general salon operating hours for that day.
CREATE OR REPLACE FUNCTION public.is_staff_on_duty(
  p_salon_id UUID,
  p_staff_id UUID,
  p_dow SMALLINT,
  p_start_time TIME,
  p_end_time TIME
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_has_staff_shifts BOOLEAN;
BEGIN
  -- Determine whether this staff member has custom shift rows defined
  SELECT EXISTS (
    SELECT 1 FROM public.working_hours
    WHERE salon_id = p_salon_id AND staff_id = p_staff_id
  ) INTO v_has_staff_shifts;

  IF v_has_staff_shifts THEN
    -- Custom schedule: Stylist is on duty ONLY if an explicit open shift covers the slot
    RETURN EXISTS (
      SELECT 1 FROM public.working_hours
      WHERE salon_id = p_salon_id
        AND staff_id = p_staff_id
        AND day_of_week = p_dow
        AND is_closed = false
        AND open_time <= p_start_time
        AND close_time >= p_end_time
    );
  ELSE
    -- Default schedule: Stylist follows general salon operating hours
    RETURN EXISTS (
      SELECT 1 FROM public.working_hours
      WHERE salon_id = p_salon_id
        AND staff_id IS NULL
        AND day_of_week = p_dow
        AND is_closed = false
        AND open_time <= p_start_time
        AND close_time >= p_end_time
    );
  END IF;
END;
$$;

-- ------------------------------------------------------------------------------
-- 7. Appointments Table
-- ------------------------------------------------------------------------------
-- Customer bookings for salon services.
-- Supports specific stylist selection and "Any Stylist" (auto-allocated to an eligible,
-- available stylist at booking time, recorded with is_any_stylist = true).
-- Instant booking decision: Valid customer bookings are created with status = 'confirmed'.

CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salon(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  staff_id UUID REFERENCES public.staff(id) ON DELETE SET NULL,
  is_any_stylist BOOLEAN NOT NULL DEFAULT false,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
  service_price NUMERIC(10, 2) NOT NULL CHECK (service_price >= 0),
  customer_notes TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_appointment_time_range CHECK (end_time > start_time)
);

COMMENT ON TABLE public.appointments IS 'Customer appointments with time zone aware timestamps, pricing snapshot, and status.';
COMMENT ON COLUMN public.appointments.staff_id IS 'Assigned stylist. Auto-allocated by the booking trigger when customer selects Any Stylist.';
COMMENT ON COLUMN public.appointments.is_any_stylist IS 'True if customer selected Any Stylist and the stylist was automatically allocated based on real availability.';
COMMENT ON COLUMN public.appointments.service_price IS 'Snapshot of the catalog price locked at booking time by the database trigger.';

-- Indexes for efficient query routing
CREATE INDEX IF NOT EXISTS idx_appointments_customer ON public.appointments(customer_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_appointments_staff_time ON public.appointments(staff_id, start_time);
CREATE INDEX IF NOT EXISTS idx_appointments_salon_time ON public.appointments(salon_id, start_time);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON public.appointments(status);

-- Database-level overlapping appointment prevention for assigned staff:
-- Disallows any two active appointments for the same staff member from overlapping in time.
-- Note: Parentheses around (tstzrange(...)) are required by PostgreSQL syntax for expression elements in EXCLUDE constraints.
ALTER TABLE public.appointments
DROP CONSTRAINT IF EXISTS no_overlapping_staff_appointments;

ALTER TABLE public.appointments
ADD CONSTRAINT no_overlapping_staff_appointments
EXCLUDE USING gist (
  staff_id WITH =,
  (tstzrange(start_time, end_time, '[)')) WITH &&
)
WHERE (staff_id IS NOT NULL AND status NOT IN ('cancelled', 'no_show'));

CREATE TRIGGER trg_appointments_updated_at
BEFORE UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ------------------------------------------------------------------------------
-- 7.1 Server-Side Booking Enforcement & Dynamic Stylist Allocation Trigger
-- ------------------------------------------------------------------------------
-- Core security & business logic trigger executed BEFORE INSERT on appointments:
--   1. Locks the singleton salon row FOR UPDATE to serialize concurrent booking requests.
--   2. Automatically derives and validates customer_id from auth.uid() for customers.
--   3. Validates that the service exists, is active, and locks service_price from catalog.
--   4. Computes end_time server-side as: start_time + service.duration_minutes.
--   5. Enforces instant booking decision: status is set to 'confirmed' server-side.
--   6. Validates local timezone boundaries (rejecting appointments crossing midnight).
--   7. Validates salon operating hours against working_hours.
--   8. If customer chose a specific stylist:
--      - Validates stylist is active and performs this service (specialties check).
--      - Validates stylist is on duty during the shift using is_staff_on_duty.
--      - Checks for existing overlapping bookings (reinforced by the GiST constraint).
--   9. If customer chose "Any Stylist" (staff_id IS NULL):
--      - Dynamically searches for an active stylist who:
--          a) Is on duty for the entire appointment duration via is_staff_on_duty.
--          b) Is qualified for the service (specialties match or empty).
--          c) Is free of overlapping appointments.
--      - If found, assigns NEW.staff_id to that stylist (with fair load balancing)
--        and sets NEW.is_any_stylist := true.
--      - If no qualified stylist is available, rejects the booking immediately.

CREATE OR REPLACE FUNCTION public.enforce_appointment_booking_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_canonical_salon_id UUID;
  v_salon_tz TEXT;
  v_service public.services%ROWTYPE;
  v_staff public.staff%ROWTYPE;
  v_is_admin BOOLEAN := false;

  -- Scheduling & Local Timezone Variables
  v_appt_start_local TIMESTAMP;
  v_appt_end_local TIMESTAMP;
  v_appt_dow SMALLINT;
  v_appt_start_time TIME;
  v_appt_end_time TIME;
  v_salon_is_closed BOOLEAN;
  v_salon_open TIME;
  v_salon_close TIME;

  -- Dynamic Stylist Allocation Variable
  v_allocated_staff_id UUID;
BEGIN
  -- Determine caller permissions
  IF auth.uid() IS NOT NULL THEN
    v_is_admin := public.is_admin_or_owner(auth.uid());
  END IF;

  -- 1. Ensure salon_id references the single canonical salon
  SELECT id, timezone INTO v_canonical_salon_id, v_salon_tz
  FROM public.salon
  LIMIT 1;

  IF v_canonical_salon_id IS NULL THEN
    RAISE EXCEPTION 'Salon profile has not been initialized. Please seed the salon entity first.';
  END IF;

  NEW.salon_id := v_canonical_salon_id;
  v_salon_tz := COALESCE(v_salon_tz, 'Asia/Kolkata');

  -- 2. Concurrency Control: Lock the singleton salon row FOR UPDATE.
  -- This serializes concurrent booking requests for this salon and completely
  -- eliminates race conditions where two simultaneous transactions could allocate the same stylist.
  PERFORM id FROM public.salon WHERE id = NEW.salon_id FOR UPDATE;

  -- 3. Customer Identity Verification
  -- Regular customers can only book for themselves (customer_id forced to auth.uid()).
  -- Admins/owners may book on behalf of any valid customer profile.
  IF NOT v_is_admin THEN
    IF auth.uid() IS NULL THEN
      RAISE EXCEPTION 'Authentication required: unauthenticated users cannot create appointments.';
    END IF;
    NEW.customer_id := auth.uid();
  ELSE
    IF NEW.customer_id IS NULL THEN
      RAISE EXCEPTION 'customer_id is required when creating an appointment as admin.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.customer_id) THEN
      RAISE EXCEPTION 'Referenced customer profile does not exist.';
    END IF;
  END IF;

  -- 4. Validate Service & Price Integrity
  -- Never trust client-supplied service_price; fetch directly from catalog.
  SELECT * INTO v_service
  FROM public.services
  WHERE id = NEW.service_id AND salon_id = NEW.salon_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Selected service does not exist for this salon.';
  END IF;

  IF NOT v_service.is_active AND NOT v_is_admin THEN
    RAISE EXCEPTION 'Selected service is currently inactive.';
  END IF;

  -- Overwrite price with official catalog price
  NEW.service_price := v_service.price;

  -- 5. Calculate end_time Server-Side
  IF NEW.start_time IS NULL THEN
    RAISE EXCEPTION 'start_time is required.';
  END IF;

  NEW.end_time := NEW.start_time + (v_service.duration_minutes * interval '1 minute');

  -- Non-admin bookings must be in the future
  IF NOT v_is_admin AND NEW.start_time <= now() THEN
    RAISE EXCEPTION 'Appointments must be booked for a future date and time.';
  END IF;

  -- 6. Enforce Instant Booking Status
  -- Valid customer bookings are created with status = 'confirmed'.
  -- Customers are forbidden from specifying arbitrary statuses.
  IF NOT v_is_admin THEN
    NEW.status := 'confirmed';
  ELSE
    NEW.status := COALESCE(NEW.status, 'confirmed');
  END IF;

  -- 7. Local Timezone Conversion & Midnight Crossing Check
  v_appt_start_local := NEW.start_time AT TIME ZONE v_salon_tz;
  v_appt_end_local := NEW.end_time AT TIME ZONE v_salon_tz;

  -- Reject appointments that cross midnight or span multiple calendar days
  IF v_appt_start_local::DATE <> v_appt_end_local::DATE THEN
    RAISE EXCEPTION 'Appointments crossing local midnight or spanning multiple days are not supported.';
  END IF;

  v_appt_dow := EXTRACT(DOW FROM v_appt_start_local)::SMALLINT;
  v_appt_start_time := v_appt_start_local::TIME;
  v_appt_end_time := v_appt_end_local::TIME;

  -- 8. Validate Salon Operating Hours
  SELECT is_closed, open_time, close_time
  INTO v_salon_is_closed, v_salon_open, v_salon_close
  FROM public.working_hours
  WHERE salon_id = NEW.salon_id
    AND staff_id IS NULL
    AND day_of_week = v_appt_dow;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Salon operating hours have not been configured for this day of the week (day %).', v_appt_dow;
  END IF;

  IF v_salon_is_closed THEN
    RAISE EXCEPTION 'The salon is closed on this day of the week.';
  END IF;

  IF v_appt_start_time < v_salon_open OR v_appt_end_time > v_salon_close THEN
    RAISE EXCEPTION 'Requested appointment (% to %) falls outside salon operating hours (% to %).',
      to_char(v_appt_start_time, 'HH24:MI'),
      to_char(v_appt_end_time, 'HH24:MI'),
      to_char(v_salon_open, 'HH24:MI'),
      to_char(v_salon_close, 'HH24:MI');
  END IF;

  -- 9. Stylist Validation & Dynamic Allocation
  IF NEW.staff_id IS NOT NULL THEN
    -- --------------------------------------------------------------------------
    -- 9A. Specific Stylist Chosen by Customer or Admin
    -- --------------------------------------------------------------------------
    NEW.is_any_stylist := COALESCE(NEW.is_any_stylist, false);

    SELECT * INTO v_staff
    FROM public.staff
    WHERE id = NEW.staff_id AND salon_id = NEW.salon_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Selected stylist does not exist for this salon.';
    END IF;

    IF NOT v_staff.is_active THEN
      RAISE EXCEPTION 'Selected stylist is currently inactive.';
    END IF;

    -- Validate specialty eligibility:
    -- If stylist specifies non-empty specialties, service name or category must match.
    -- An empty specialties array indicates the stylist performs all salon services.
    IF array_length(v_staff.specialties, 1) > 0 THEN
      IF NOT (
        v_service.name = ANY(v_staff.specialties)
        OR v_service.category = ANY(v_staff.specialties)
      ) THEN
        RAISE EXCEPTION 'Stylist "%" does not perform "%" services.', v_staff.full_name, v_service.name;
      END IF;
    END IF;

    -- Validate Stylist Working Shift using unified helper
    IF NOT public.is_staff_on_duty(NEW.salon_id, NEW.staff_id, v_appt_dow, v_appt_start_time, v_appt_end_time) THEN
      RAISE EXCEPTION 'Stylist "%" is not on duty during the requested time (% to %).',
        v_staff.full_name,
        to_char(v_appt_start_time, 'HH24:MI'),
        to_char(v_appt_end_time, 'HH24:MI');
    END IF;

    -- Check for conflicting appointments on this specific stylist
    IF EXISTS (
      SELECT 1 FROM public.appointments ap
      WHERE ap.staff_id = NEW.staff_id
        AND ap.status NOT IN ('cancelled', 'no_show')
        AND (tstzrange(ap.start_time, ap.end_time, '[)')) && (tstzrange(NEW.start_time, NEW.end_time, '[)'))
    ) THEN
      RAISE EXCEPTION 'Stylist "%" is already booked during this time slot.', v_staff.full_name;
    END IF;

  ELSE
    -- --------------------------------------------------------------------------
    -- 9B. "Any Stylist" (staff_id IS NULL) Dynamic Allocation
    -- --------------------------------------------------------------------------
    -- Customer requests any available stylist.
    -- The database dynamically searches for an active stylist who:
    --   1. Belongs to this salon and is marked active.
    --   2. Is qualified to perform this service (specialty match or all-rounder).
    --   3. Is scheduled on duty for [start_time, end_time) via is_staff_on_duty.
    --   4. Has NO overlapping confirmed/pending appointment.
    -- If multiple stylists qualify, picks the one with fewest bookings on that date
    -- to maintain fair load-balancing across the team.

    NEW.is_any_stylist := true;

    SELECT s.id INTO v_allocated_staff_id
    FROM public.staff s
    WHERE s.salon_id = NEW.salon_id
      AND s.is_active = true
      -- Specialty eligibility check
      AND (
        array_length(s.specialties, 1) IS NULL
        OR array_length(s.specialties, 1) = 0
        OR v_service.name = ANY(s.specialties)
        OR v_service.category = ANY(s.specialties)
      )
      -- Working shift check (using unified helper)
      AND public.is_staff_on_duty(NEW.salon_id, s.id, v_appt_dow, v_appt_start_time, v_appt_end_time)
      -- Range conflict check against assigned appointments
      AND NOT EXISTS (
        SELECT 1 FROM public.appointments ap
        WHERE ap.staff_id = s.id
          AND ap.status NOT IN ('cancelled', 'no_show')
          AND (tstzrange(ap.start_time, ap.end_time, '[)')) && (tstzrange(NEW.start_time, NEW.end_time, '[)'))
      )
    ORDER BY
      -- Load balancing: prioritize stylist with fewest appointments on this calendar date
      (
        SELECT count(*)
        FROM public.appointments ap2
        WHERE ap2.staff_id = s.id
          AND ap2.status NOT IN ('cancelled', 'no_show')
          AND ap2.start_time::date = NEW.start_time::date
      ) ASC,
      s.display_order ASC,
      s.id ASC
    LIMIT 1;

    IF v_allocated_staff_id IS NULL THEN
      RAISE EXCEPTION 'No available stylist with the required specialty is on duty for the requested time slot.';
    END IF;

    -- Allocate the verified available stylist to the appointment row
    NEW.staff_id := v_allocated_staff_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_appointment_booking_rules ON public.appointments;
CREATE TRIGGER trg_enforce_appointment_booking_rules
BEFORE INSERT ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.enforce_appointment_booking_rules();

-- ------------------------------------------------------------------------------
-- 7.2 Customer Appointment Modification Restriction Trigger
-- ------------------------------------------------------------------------------
-- Ensures customers cannot modify protected booking details (service, time, price, stylist)
-- and can ONLY cancel their own eligible future appointments.

CREATE OR REPLACE FUNCTION public.restrict_customer_appointment_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- If caller is authenticated customer (non-admin, non-staff)
  IF auth.uid() IS NOT NULL AND NOT public.is_admin_or_owner(auth.uid()) THEN
    -- 1. Must be the customer who owns this appointment
    IF OLD.customer_id <> auth.uid() THEN
      RAISE EXCEPTION 'Access Denied: You can only update your own appointments.';
    END IF;

    -- 2. Prevent modifying protected booking fields
    IF NEW.customer_id <> OLD.customer_id
       OR NEW.salon_id <> OLD.salon_id
       OR NEW.service_id <> OLD.service_id
       OR NEW.staff_id IS DISTINCT FROM OLD.staff_id
       OR NEW.is_any_stylist IS DISTINCT FROM OLD.is_any_stylist
       OR NEW.service_price <> OLD.service_price
       OR NEW.start_time <> OLD.start_time
       OR NEW.end_time <> OLD.end_time
       OR NEW.created_at <> OLD.created_at THEN
      RAISE EXCEPTION 'Protected booking fields (service, stylist, time, price) cannot be altered directly. Please cancel and create a new booking to reschedule.';
    END IF;

    -- 3. Customers may ONLY cancel an appointment
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      IF NEW.status <> 'cancelled' THEN
        RAISE EXCEPTION 'Customers may only change appointment status to cancelled.';
      END IF;

      -- Check cancellation eligibility
      IF OLD.status IN ('completed', 'cancelled', 'no_show') THEN
        RAISE EXCEPTION 'This appointment is already % and cannot be cancelled.', OLD.status;
      END IF;

      IF OLD.start_time <= now() THEN
        RAISE EXCEPTION 'Past or ongoing appointments cannot be cancelled.';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_restrict_customer_appointment_update ON public.appointments;
CREATE TRIGGER trg_restrict_customer_appointment_update
BEFORE UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.restrict_customer_appointment_update();

-- ==============================================================================
-- 8. Row Level Security (RLS) Policies
-- ==============================================================================

-- Enable RLS on every table without exception
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salon ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 8.1 PROFILES POLICIES
-- ------------------------------------------------------------------------------
-- Customers can read their own profile.
-- Owners, admins, and active staff can read customer profiles to identify appointment holders.
CREATE POLICY "Users can read own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  auth.uid() = id
  OR public.is_admin_or_owner(auth.uid())
  OR EXISTS (
    SELECT 1 FROM public.staff
    WHERE staff.user_id = auth.uid() AND staff.is_active = true
  )
);

-- Users can update their own profile details (full_name, phone, avatar_url).
-- Role escalation is protected via trg_prevent_role_escalation trigger.
CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Owners/Admins have full administrative access to profiles
CREATE POLICY "Admins have full access to profiles"
ON public.profiles
FOR ALL
TO authenticated
USING (public.is_admin_or_owner(auth.uid()))
WITH CHECK (public.is_admin_or_owner(auth.uid()));

-- ------------------------------------------------------------------------------
-- 8.2 SALON POLICIES
-- ------------------------------------------------------------------------------
-- Public (anonymous + authenticated) can view salon details
CREATE POLICY "Salon details are publicly readable"
ON public.salon
FOR SELECT
TO public
USING (true);

-- Only owners and admins can update or insert salon details
CREATE POLICY "Admins can manage salon profile"
ON public.salon
FOR ALL
TO authenticated
USING (public.is_admin_or_owner(auth.uid()))
WITH CHECK (public.is_admin_or_owner(auth.uid()));

-- ------------------------------------------------------------------------------
-- 8.3 SERVICES POLICIES
-- ------------------------------------------------------------------------------
-- Public can only view active services
CREATE POLICY "Active services are publicly readable"
ON public.services
FOR SELECT
TO public
USING (is_active = true);

-- Owners and admins can view all services (including deactivated ones)
CREATE POLICY "Admins can read all services"
ON public.services
FOR SELECT
TO authenticated
USING (public.is_admin_or_owner(auth.uid()));

-- Only owners and admins can insert, update, or delete services
CREATE POLICY "Admins can manage services"
ON public.services
FOR ALL
TO authenticated
USING (public.is_admin_or_owner(auth.uid()))
WITH CHECK (public.is_admin_or_owner(auth.uid()));

-- ------------------------------------------------------------------------------
-- 8.4 STAFF POLICIES
-- ------------------------------------------------------------------------------
-- Public can only view active staff members
CREATE POLICY "Active staff members are publicly readable"
ON public.staff
FOR SELECT
TO public
USING (is_active = true);

-- Owners and admins can view all staff (including inactive)
CREATE POLICY "Admins can read all staff"
ON public.staff
FOR SELECT
TO authenticated
USING (public.is_admin_or_owner(auth.uid()));

-- Only owners and admins can insert, update, or delete staff
CREATE POLICY "Admins can manage staff"
ON public.staff
FOR ALL
TO authenticated
USING (public.is_admin_or_owner(auth.uid()))
WITH CHECK (public.is_admin_or_owner(auth.uid()));

-- ------------------------------------------------------------------------------
-- 8.5 WORKING HOURS POLICIES
-- ------------------------------------------------------------------------------
-- Public can view operating hours and active staff hours
CREATE POLICY "Working hours are publicly readable"
ON public.working_hours
FOR SELECT
TO public
USING (
  staff_id IS NULL
  OR EXISTS (
    SELECT 1 FROM public.staff
    WHERE staff.id = working_hours.staff_id AND staff.is_active = true
  )
);

-- Only owners and admins can manage working hours
CREATE POLICY "Admins can manage working hours"
ON public.working_hours
FOR ALL
TO authenticated
USING (public.is_admin_or_owner(auth.uid()))
WITH CHECK (public.is_admin_or_owner(auth.uid()));

-- ------------------------------------------------------------------------------
-- 8.6 APPOINTMENTS POLICIES
-- ------------------------------------------------------------------------------
-- Authenticated customers can view ONLY their own appointments.
-- Staff can view appointments assigned to them.
-- Owners/Admins can view all appointments.
CREATE POLICY "Customers can read own appointments"
ON public.appointments
FOR SELECT
TO authenticated
USING (
  auth.uid() = customer_id
  OR public.is_admin_or_owner(auth.uid())
  OR (
    staff_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.staff
      WHERE staff.id = appointments.staff_id AND staff.user_id = auth.uid()
    )
  )
);

-- Authenticated customers can create appointments for themselves.
-- Status is automatically confirmed by the BEFORE INSERT trigger.
CREATE POLICY "Customers can create own appointments"
ON public.appointments
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = customer_id
  AND status = 'confirmed'
);

-- Customers can update their own appointments to cancel them.
-- The restrict_customer_appointment_update trigger enforces that only cancellation is allowed.
CREATE POLICY "Customers can cancel own appointments"
ON public.appointments
FOR UPDATE
TO authenticated
USING (auth.uid() = customer_id)
WITH CHECK (
  auth.uid() = customer_id
  AND status = 'cancelled'
);

-- Owners and admins have full management permissions on all appointments
CREATE POLICY "Admins have full access to appointments"
ON public.appointments
FOR ALL
TO authenticated
USING (public.is_admin_or_owner(auth.uid()))
WITH CHECK (public.is_admin_or_owner(auth.uid()));

-- ------------------------------------------------------------------------------
-- 9. Explicit Function Execution Permissions (Hardening)
-- ------------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.is_admin_or_owner(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_or_owner(UUID) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.prevent_role_escalation() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prevent_role_escalation() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.is_staff_on_duty(UUID, UUID, SMALLINT, TIME, TIME) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_staff_on_duty(UUID, UUID, SMALLINT, TIME, TIME) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.enforce_appointment_booking_rules() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.enforce_appointment_booking_rules() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.restrict_customer_appointment_update() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.restrict_customer_appointment_update() TO authenticated, service_role;

-- ------------------------------------------------------------------------------
-- 10. Table & Schema Permissions (Standard PostgREST Grants)
-- ------------------------------------------------------------------------------
-- Ensure PostgREST roles (anon, authenticated, service_role) have table access.
-- Row Level Security (RLS) policies govern actual row-level visibility and operations.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;

COMMIT;
