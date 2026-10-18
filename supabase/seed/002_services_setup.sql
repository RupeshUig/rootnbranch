-- ==============================================================================
-- Root N Branch — Initial Salon Services Seed Script
-- File: supabase/seed/002_services_setup.sql
-- Description:
--   Seeds the baseline 21-service catalog for Root N Branch across 6 core categories
--   (Hair, Beard, Shave, Spa, Grooming, Color) linked dynamically to the singleton salon entity.
--
-- Safety & Idempotency:
--   - Wrapped in a transaction block (BEGIN...COMMIT).
--   - Safety Guard (Prices Pending):
--       public.services.price is defined as NUMERIC(10, 2) NOT NULL CHECK (price >= 0).
--       Commercial prices have not yet been approved (pending). Rather than inventing
--       unverified numbers or using zero placeholders, prices are represented as NULL
--       and protected by an executable DO block guard that aborts execution immediately.
--   - Duplicate Prevention Strategy:
--       Because public.services has a PRIMARY KEY on (id) but no UNIQUE constraint
--       on (salon_id, name), native `ON CONFLICT (salon_id, name)` cannot be used.
--       Instead, idempotency is enforced via a `WHERE NOT EXISTS` subquery matching
--       on (salon_id, name). If a service with the same name already exists for
--       the salon, it will not be duplicated on repeated runs.
--   - Does NOT touch salon, staff, working_hours, appointments, or user profiles.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 0. Safety Guard: Prevent Execution While Prices Are Pending
-- ------------------------------------------------------------------------------
-- This DO block raises an exception before any INSERT can take place.
-- Remove or comment out this block only after actual approved prices (in INR)
-- have replaced the pending price values in the VALUES table below.
-- ------------------------------------------------------------------------------
DO $$
BEGIN
  RAISE EXCEPTION 'PRICES PENDING: Cannot execute 002_services_setup.sql because service prices have not yet been approved. Replace pending price values with verified INR figures and remove this safety guard before running.';
END $$;

-- ------------------------------------------------------------------------------
-- 1. Services Catalog Insertion (21 Approved Services)
-- ------------------------------------------------------------------------------
-- Schema columns:
--   - salon_id: UUID NOT NULL REFERENCES public.salon(id) (Resolved via salon_entity CTE)
--   - name: TEXT NOT NULL (Service title)
--   - category: TEXT NOT NULL (Service category matching staff specialties)
--   - description: TEXT (Optional service details, or NULL)
--   - price: NUMERIC(10, 2) NOT NULL CHECK (price >= 0) (Pending, currently NULL)
--   - duration_minutes: INTEGER NOT NULL CHECK (duration_minutes > 0) (Service duration)
--   - is_active: BOOLEAN NOT NULL DEFAULT true (Availability flag)
--   - display_order: INTEGER NOT NULL DEFAULT 0 (Ordering priority for UI display)
-- ------------------------------------------------------------------------------

WITH salon_entity AS (
  SELECT id FROM public.salon WHERE is_singleton = true LIMIT 1
)
INSERT INTO public.services (
  salon_id,
  name,
  category,
  description,
  price,
  duration_minutes,
  is_active,
  display_order
)
SELECT
  salon_entity.id,
  svc.name,
  svc.category,
  svc.description,
  svc.price,
  svc.duration_minutes,
  svc.is_active,
  svc.display_order
FROM salon_entity
CROSS JOIN (
  VALUES
    -- Format: (name, category, description, price, duration_minutes, is_active, display_order)
    -- Hair Services (1-4)
    ('Classic Haircut', 'Hair', 'Precision scissor and clipper cut tailored to facial structure.', NULL::NUMERIC(10, 2), 30, true, 1),
    ('Fade & Taper Haircut', 'Hair', 'Skin fade, taper, or blend with precision edge-up detailing.', NULL::NUMERIC(10, 2), 45, true, 2),
    ('Kids / Junior Haircut', 'Hair', 'Gentle and patient haircut styling for boys under 12 years.', NULL::NUMERIC(10, 2), 30, true, 3),
    ('Hair Wash & Blow-Dry Styling', 'Hair', 'Clarifying scalp wash, conditioning, and structured blow-dry styling.', NULL::NUMERIC(10, 2), 20, true, 4),

    -- Beard Grooming (5-7)
    ('Classic Beard Trim', 'Beard', 'Length reduction, shape maintenance, and cheek contour cleanup.', NULL::NUMERIC(10, 2), 20, true, 5),
    ('Beard Sculpting & Line-Up', 'Beard', 'Detailed shaping, razor edge alignment, and beard oil treatment.', NULL::NUMERIC(10, 2), 30, true, 6),
    ('Moustache Grooming & Styling', 'Beard', 'Precision moustache trimming, shaping, and styling wax application.', NULL::NUMERIC(10, 2), 15, true, 7),

    -- Shave Services (8-10)
    ('Traditional Hot Towel Shave', 'Shave', 'Classic straight-razor shave with pre-shave oil and warm towels.', NULL::NUMERIC(10, 2), 30, true, 8),
    ('Royal Luxury Shave', 'Shave', 'Multi-step shaving ritual with facial massage, hot & cold towels, and aftershave balm.', NULL::NUMERIC(10, 2), 45, true, 9),
    ('Head Shave (Razor / Clipper)', 'Shave', 'Smooth full-head razor shave with soothing scalp balm.', NULL::NUMERIC(10, 2), 30, true, 10),

    -- Spa & Treatments (11-13)
    ('Scalp Massage & Hair Tonic', 'Spa', 'Invigorating pressure-point scalp massage with nourishing herbal tonic.', NULL::NUMERIC(10, 2), 25, true, 11),
    ('Deep Conditioning Hair Spa', 'Spa', 'Restorative deep-creme treatment with steam infusion and hair hydration.', NULL::NUMERIC(10, 2), 45, true, 12),
    ('Anti-Dandruff Scalp Treatment', 'Spa', 'Exfoliating clarifying scalp scrub and anti-fungal soothing serum.', NULL::NUMERIC(10, 2), 45, true, 13),

    -- Face & Grooming (14-18)
    ('Express Face Clean-Up', 'Grooming', 'Rapid cleanse, gentle exfoliation, and clarifying herbal pack.', NULL::NUMERIC(10, 2), 30, true, 14),
    ('Charcoal Detox Facial', 'Grooming', 'Activated charcoal deep-pore cleansing and blackhead removal mask.', NULL::NUMERIC(10, 2), 45, true, 15),
    ('De-Tan Face & Neck Treatment', 'Grooming', 'Antioxidant skin brightening pack to reverse sun tan and pollution damage.', NULL::NUMERIC(10, 2), 30, true, 16),
    ('Under-Eye Dark Circle Therapy', 'Grooming', 'Cooling peptide serum infusion and eye massage to reduce puffiness.', NULL::NUMERIC(10, 2), 20, true, 17),
    ('Relaxing Neck & Shoulder Massage', 'Grooming', 'Acupressure relief for upper back, neck, and shoulder muscle tension.', NULL::NUMERIC(10, 2), 20, true, 18),

    -- Color Services (19-21)
    ('Beard Color / Gray Camouflage', 'Color', 'Natural-finish ammonia-free beard coloring to blend gray hairs.', NULL::NUMERIC(10, 2), 30, true, 19),
    ('Hair Color & Gray Blending', 'Color', 'Full-head coverage or subtle natural gray blending for men.', NULL::NUMERIC(10, 2), 45, true, 20),
    ('Fashion Hair Streak & Highlights', 'Color', 'Targeted crown streaks or creative tone highlights.', NULL::NUMERIC(10, 2), 60, true, 21)
) AS svc(name, category, description, price, duration_minutes, is_active, display_order)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.services s
  WHERE s.salon_id = salon_entity.id
    AND s.name = svc.name
);

COMMIT;

-- ------------------------------------------------------------------------------
-- Verification Query (Run after execution once prices are populated and guard is disabled):
-- ------------------------------------------------------------------------------
-- SELECT display_order, name, category, price, duration_minutes, is_active
-- FROM public.services
-- ORDER BY display_order;
