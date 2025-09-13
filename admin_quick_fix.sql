-- Quick Fix for Admin Panel Access Issue
-- Execute this directly in Supabase SQL Editor

-- Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create or update admin user
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
  'dev@zazadance.com',
  'Admin User',
  'admin',
  true,
  true,
  NOW(),
  NOW()
) 
ON CONFLICT (email) 
DO UPDATE SET 
  role = 'admin',
  is_approved = true,
  is_active = true,
  updated_at = NOW();

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admin can view all users" ON public.users;
DROP POLICY IF EXISTS "Admin can update all users" ON public.users;
DROP POLICY IF EXISTS "Admin can delete users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Allow user registration" ON public.users;

-- Create admin SELECT policy (allows viewing all users including unapproved)
CREATE POLICY "Admin can view all users" ON public.users
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
  )
  OR
  auth.uid() = id
);

-- Create admin UPDATE policy
CREATE POLICY "Admin can update all users" ON public.users
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
  )
  OR
  auth.uid() = id
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
  )
  OR
  auth.uid() = id
);

-- Create admin DELETE policy
CREATE POLICY "Admin can delete users" ON public.users
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.email = 'dev@zazadance.com'
    AND admin_users.role = 'admin'
  )
);

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Allow new user registrations
CREATE POLICY "Allow user registration" ON public.users
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Verify the admin user exists
SELECT 
  id,
  email,
  name,
  role,
  is_approved,
  is_active,
  created_at
FROM public.users 
WHERE email = 'dev@zazadance.com';

-- Show pending users that admin should be able to see
SELECT 
  id,
  email,
  name,
  role,
  is_approved,
  is_active,
  created_at
FROM public.users 
WHERE is_approved = false
ORDER BY created_at DESC;