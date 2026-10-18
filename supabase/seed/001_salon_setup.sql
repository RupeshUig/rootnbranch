-- ==============================================================================
-- Root N Branch — Initial Salon & Operating Hours Seed Script
-- File: supabase/seed/001_salon_setup.sql
-- Description:
--   Seeds the singleton salon record for Root N Branch in Kolkata, West Bengal
--   and configures baseline salon operating hours (10:00 AM - 10:00 PM, 7 days/week).
--
-- Safety & Idempotency:
--   - Wrapped in a transaction block (BEGIN...COMMIT).
--   - Uses ON CONFLICT DO NOTHING to prevent duplicate singleton salon rows
--     or duplicate schedule entries if executed multiple times.
--   - Does NOT touch staff, services, appointments, or user profiles.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Singleton Salon Profile
-- ------------------------------------------------------------------------------
-- Salon details:
--   Name: Root N Branch
--   Phone: +91 78081 91981
--   Email: contact@rootnbranch.in
--   Address: BE-92, 1st Ave Rd, BE Block, 1 Bidhannagar, Bidhannagar, Kolkata
--   City: Kolkata
--   State: West Bengal
--   PIN Code: 700064
--   Country: India
--   Timezone: Asia/Kolkata (Indian Standard Time, UTC+05:30)
-- ------------------------------------------------------------------------------

INSERT INTO public.salon (
  name,
  tagline,
  description,
  phone,
  email,
  address_line1,
  address_line2,
  city,
  state,
  postal_code,
  country,
  timezone,
  logo_url,
  banner_url
) VALUES (
  'Root N Branch',
  NULL,
  NULL,
  '+91 78081 91981',
  'contact@rootnbranch.in',
  'BE-92, 1st Ave Rd, BE Block, 1 Bidhannagar, Bidhannagar, Kolkata',
  NULL,
  'Kolkata',
  'West Bengal',
  '700064',
  'India',
  'Asia/Kolkata',
  NULL,
  NULL
)
ON CONFLICT (is_singleton) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 2. Salon Operating Hours (Sunday through Saturday)
-- ------------------------------------------------------------------------------
-- Operating schedule: 10:00 AM to 10:00 PM (10:00 to 22:00) every day.
-- No weekly closing days (is_closed = false for all 7 days).
-- staff_id IS NULL represents salon-wide operating hours.
--
-- Day of Week index mapping:
--   0 = Sunday
--   1 = Monday
--   2 = Tuesday
--   3 = Wednesday
--   4 = Thursday
--   5 = Friday
--   6 = Saturday
-- ------------------------------------------------------------------------------

WITH salon_entity AS (
  SELECT id FROM public.salon WHERE is_singleton = true LIMIT 1
)
INSERT INTO public.working_hours (
  salon_id,
  staff_id,
  day_of_week,
  open_time,
  close_time,
  is_closed
)
SELECT
  salon_entity.id,
  NULL, -- NULL indicates salon-wide operating hours
  schedule.day_of_week,
  schedule.open_time,
  schedule.close_time,
  schedule.is_closed
FROM salon_entity
CROSS JOIN (
  VALUES
    -- (day_of_week, open_time, close_time, is_closed)
    (0, '10:00'::TIME, '22:00'::TIME, false), -- Sunday
    (1, '10:00'::TIME, '22:00'::TIME, false), -- Monday
    (2, '10:00'::TIME, '22:00'::TIME, false), -- Tuesday
    (3, '10:00'::TIME, '22:00'::TIME, false), -- Wednesday
    (4, '10:00'::TIME, '22:00'::TIME, false), -- Thursday
    (5, '10:00'::TIME, '22:00'::TIME, false), -- Friday
    (6, '10:00'::TIME, '22:00'::TIME, false)  -- Saturday
) AS schedule(day_of_week, open_time, close_time, is_closed)
ON CONFLICT (salon_id, day_of_week) WHERE staff_id IS NULL DO NOTHING;

COMMIT;

-- ------------------------------------------------------------------------------
-- Verification Queries (Run after execution to inspect configured values):
-- ------------------------------------------------------------------------------
-- SELECT * FROM public.salon;
-- SELECT day_of_week, open_time, close_time, is_closed
-- FROM public.working_hours
-- WHERE staff_id IS NULL
-- ORDER BY day_of_week;
