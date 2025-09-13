-- Admin User Setup and RLS Policies Migration
-- This migration creates the admin user and sets up proper RLS policies for admin access

-- First, enable RLS on the users table if not already enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts (they may not exist yet)
DROP POLICY IF EXISTS "Admin can view all users" ON public.users;
DROP POLICY IF EXISTS "Admin can update all users" ON public.users;
DROP POLICY IF EXISTS "Admin can delete users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;

-- Create the admin user if it doesn't exist
-- We need to check if this user exists before inserting
DO $$
DECLARE
  admin_user_id UUID;
  admin_email TEXT := 'dev@zazadance.com';
BEGIN
  -- Check if admin user already exists
  SELECT id INTO admin_user_id 
  FROM public.users 
  WHERE email = admin_email;
  
  -- If admin user doesn't exist, create it
  IF admin_user_id IS NULL THEN
    -- Insert admin user with a new UUID
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
      'Admin User',
      'admin',
      true,
      true,
      NOW(),
      NOW()
    );
    
    RAISE NOTICE 'Admin user created successfully with email: %', admin_email;
  ELSE
    -- Update existing user to ensure admin privileges
    UPDATE public.users 
    SET 
      role = 'admin',
      is_approved = true,
      is_active = true,
      updated_at = NOW()
    WHERE id = admin_user_id;
    
    RAISE NOTICE 'Admin user updated successfully with email: %', admin_email;
  END IF;
END $$;

-- Create RLS policies for admin access

-- Policy 1: Admin can view all users (including unapproved ones)
CREATE POLICY "Admin can view all users" ON public.users
FOR SELECT
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
  OR
  auth.uid() = id  -- Users can still see their own records
);

-- Policy 2: Admin can update all users
CREATE POLICY "Admin can update all users" ON public.users
FOR UPDATE
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
  OR
  auth.uid() = id  -- Users can still update their own records
)
WITH CHECK (
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

-- Policy 3: Admin can delete users
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
);

-- Policy 4: Regular users can view their own profile
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Insert policy for new user registrations (anon users can insert)
CREATE POLICY "Allow user registration" ON public.users
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Verify the setup by showing admin user details
DO $$
DECLARE
  admin_record RECORD;
BEGIN
  SELECT id, email, name, role, is_approved, is_active, created_at
  INTO admin_record
  FROM public.users 
  WHERE email = 'dev@zazadance.com';
  
  IF FOUND THEN
    RAISE NOTICE 'Admin user verification:';
    RAISE NOTICE '  ID: %', admin_record.id;
    RAISE NOTICE '  Email: %', admin_record.email;
    RAISE NOTICE '  Name: %', admin_record.name;
    RAISE NOTICE '  Role: %', admin_record.role;
    RAISE NOTICE '  Approved: %', admin_record.is_approved;
    RAISE NOTICE '  Active: %', admin_record.is_active;
    RAISE NOTICE '  Created: %', admin_record.created_at;
  ELSE
    RAISE EXCEPTION 'Admin user was not created successfully';
  END IF;
END $$;