-- COMPLETE ADMIN SETUP FOR ZAZA DANCE STUDIO
-- This script sets up everything needed for admin panel access

-- Step 1: Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admin can view all users" ON public.users;
DROP POLICY IF EXISTS "Admin can update all users" ON public.users;
DROP POLICY IF EXISTS "Admin can delete users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Allow user registration" ON public.users;

-- Step 3: Create admin user in auth.users table (this needs to be done manually or via Supabase Auth)
-- NOTE: You need to manually create a user with email 'dev@zazadance.com' in Supabase Auth dashboard
-- Then get the UUID from auth.users and use it below

-- Step 4: Create or update admin user in public.users table
-- First let's try to find if there's already a user with this email
DO $$
DECLARE
  admin_user_id UUID;
  auth_user_id UUID;
  admin_email TEXT := 'dev@zazadance.com';
BEGIN
  -- Try to find existing auth user first
  SELECT id INTO auth_user_id 
  FROM auth.users 
  WHERE email = admin_email;
  
  -- Check if admin user already exists in public.users
  SELECT id INTO admin_user_id 
  FROM public.users 
  WHERE email = admin_email;
  
  -- If we have auth user but no public user, create the public user
  IF auth_user_id IS NOT NULL AND admin_user_id IS NULL THEN
    INSERT INTO public.users (
      id,
      email,
      name,
      role,
      is_approved,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      auth_user_id,
      admin_email,
      'Admin User',
      'admin',
      true,
      true,
      NOW(),
      NOW()
    );
    RAISE NOTICE 'Admin user created in public.users with auth UUID: %', auth_user_id;
    
  -- If we have both, update the public user to ensure admin privileges
  ELSIF auth_user_id IS NOT NULL AND admin_user_id IS NOT NULL THEN
    UPDATE public.users 
    SET 
      id = auth_user_id, -- Ensure IDs match
      role = 'admin',
      is_approved = true,
      is_active = true,
      updated_at = NOW()
    WHERE email = admin_email;
    RAISE NOTICE 'Admin user updated in public.users with auth UUID: %', auth_user_id;
    
  -- If no auth user exists, create a placeholder in public.users
  ELSIF auth_user_id IS NULL AND admin_user_id IS NULL THEN
    INSERT INTO public.users (
      id,
      email,
      name,
      role,
      is_approved,
      is_active,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      admin_email,
      'Admin User (Create auth user)',
      'admin',
      true,
      true,
      NOW(),
      NOW()
    );
    RAISE NOTICE 'Placeholder admin user created. Please create auth user with email: %', admin_email;
    
  -- If only public user exists, keep it
  ELSE
    UPDATE public.users 
    SET 
      role = 'admin',
      is_approved = true,
      is_active = true,
      updated_at = NOW()
    WHERE email = admin_email;
    RAISE NOTICE 'Existing admin user updated: %', admin_email;
  END IF;
END $$;

-- Step 5: Create comprehensive RLS policies

-- Policy 1: Admin can view all users (including unapproved ones)
CREATE POLICY "Admin can view all users" ON public.users
FOR SELECT
TO authenticated
USING (
  -- Allow if user is admin
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
    AND admin_users.is_approved = true
    AND admin_users.is_active = true
  )
  OR
  -- Allow users to see their own record
  auth.uid() = id
);

-- Policy 2: Admin can update all users
CREATE POLICY "Admin can update all users" ON public.users
FOR UPDATE
TO authenticated
USING (
  -- Allow if user is admin
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
    AND admin_users.is_approved = true
    AND admin_users.is_active = true
  )
  OR
  -- Allow users to update their own record
  auth.uid() = id
)
WITH CHECK (
  -- Same check for the updated data
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
    AND admin_users.is_approved = true
    AND admin_users.is_active = true
  )
  OR
  auth.uid() = id
);

-- Policy 3: Admin can delete users (except themselves)
CREATE POLICY "Admin can delete users" ON public.users
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
    AND admin_users.is_approved = true
    AND admin_users.is_active = true
  )
  AND auth.uid() != id  -- Don't allow admin to delete themselves
);

-- Policy 4: Regular users can view their own profile
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy 5: Allow new user registrations (for app signups)
CREATE POLICY "Allow user registration" ON public.users
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Step 6: Create a function to help with admin user management
CREATE OR REPLACE FUNCTION public.create_admin_user_if_needed()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  admin_email TEXT := 'dev@zazadance.com';
  auth_user_id UUID;
  public_user_id UUID;
BEGIN
  -- Check if auth user exists
  SELECT id INTO auth_user_id FROM auth.users WHERE email = admin_email;
  
  -- Check if public user exists
  SELECT id INTO public_user_id FROM public.users WHERE email = admin_email;
  
  -- If auth user exists but public user doesn't, create it
  IF auth_user_id IS NOT NULL AND public_user_id IS NULL THEN
    INSERT INTO public.users (
      id, email, name, role, is_approved, is_active, created_at, updated_at
    ) VALUES (
      auth_user_id, admin_email, 'Admin User', 'admin', true, true, NOW(), NOW()
    );
  END IF;
END;
$$;

-- Step 7: Verification queries
DO $$
BEGIN
  RAISE NOTICE '=== ADMIN SETUP VERIFICATION ===';
  
  -- Show admin user in auth.users (if exists)
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = 'dev@zazadance.com') THEN
    RAISE NOTICE 'Auth user exists: dev@zazadance.com';
  ELSE
    RAISE NOTICE 'WARNING: Auth user does NOT exist. Please create manually in Supabase Auth.';
  END IF;
  
  -- Show admin user in public.users
  IF EXISTS (SELECT 1 FROM public.users WHERE email = 'dev@zazadance.com') THEN
    RAISE NOTICE 'Public user exists: dev@zazadance.com';
  ELSE
    RAISE NOTICE 'ERROR: Public user does NOT exist!';
  END IF;
  
  RAISE NOTICE '=== END VERIFICATION ===';
END $$;

-- Step 8: Show current pending users (what admin should see)
SELECT 
  'PENDING USERS:' AS info,
  COUNT(*) AS count
FROM public.users 
WHERE is_approved = false;

-- Show admin user details
SELECT 
  'ADMIN USER:' AS info,
  id,
  email,
  name,
  role,
  is_approved,
  is_active,
  created_at
FROM public.users 
WHERE email = 'dev@zazadance.com';

-- Show all current policies on users table
SELECT 
  'RLS POLICIES:' AS info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'users' 
ORDER BY policyname;