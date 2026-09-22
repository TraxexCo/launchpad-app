-- 202609220003_seed_data.sql
-- Run this in your Supabase SQL Editor to populate mock data for your defense presentation!

-- We will insert a couple of mock users directly into auth.users.
-- However, creating auth.users in Supabase via SQL requires bypassing the API, 
-- which can be complex due to the encrypted passwords.
-- Instead, we will just create the Profiles, Jobs, and Proposals. 
-- Note: The `auth.users` row will not exist for these, so you can't log in as them, 
-- but they will appear perfectly in the app for the current student/business to interact with!

DO $$
DECLARE
  biz1_id uuid := gen_random_uuid();
  biz2_id uuid := gen_random_uuid();
  student1_id uuid := gen_random_uuid();
  job1_id uuid := gen_random_uuid();
  job2_id uuid := gen_random_uuid();
BEGIN
  -- 1. Create Mock Profiles
  INSERT INTO public.profiles (id, role, full_name, avatar_path) VALUES
  (biz1_id, 'business', 'TechNova Solutions', NULL),
  (biz2_id, 'business', 'GreenLeaf Cafe', NULL),
  (student1_id, 'student', 'Alex Dev', NULL);

  -- 2. Create Role-Specific Profiles
  INSERT INTO public.business_profiles (user_id, company_name, industry, description) VALUES
  (biz1_id, 'TechNova Solutions', 'IT Services', 'A leading local IT provider.'),
  (biz2_id, 'GreenLeaf Cafe', 'Food & Beverage', 'A cozy cafe looking to digitize orders.');

  INSERT INTO public.student_profiles (user_id, headline, bio, course, school, github_username) VALUES
  (student1_id, 'Full Stack Developer', 'I love building Flutter apps.', 'BSIT', 'NU Baliwag', 'alexdev');

  -- 3. Create Mock Jobs
  INSERT INTO public.jobs (id, business_id, title, description, budget, timeframe, status) VALUES
  (job1_id, biz1_id, 'Need a POS System', 'We need a simple Point of Sale system built in Flutter.', 5000.00, '1 Month', 'open'),
  (job2_id, biz2_id, 'Cafe Ordering App', 'Looking for a student to build an ordering app for our cafe.', 8000.00, '2 Months', 'open');

  -- 4. Create Mock Proposals
  INSERT INTO public.proposals (job_id, student_id, cover_letter, bid_amount, estimated_days, status) VALUES
  (job1_id, student1_id, 'I have built POS systems before. I can do this in 3 weeks!', 4500.00, 21, 'pending');

END $$;
