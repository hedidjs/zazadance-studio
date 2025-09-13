-- Admin RPC Functions for bypassing RLS
-- These functions allow admin panel to access all users

-- Function to get all users (bypassing RLS)
CREATE OR REPLACE FUNCTION get_all_users_admin()
RETURNS TABLE(
  id UUID,
  email TEXT,
  username TEXT,
  display_name TEXT,
  full_name TEXT,
  phone TEXT,
  address TEXT,
  user_type TEXT,
  parent_name TEXT,
  student_name TEXT,
  profile_image_url TEXT,
  role TEXT,
  is_approved BOOLEAN,
  approval_status TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    id,
    email,
    username,
    display_name,
    full_name,
    phone,
    address,
    user_type,
    parent_name,
    student_name,
    profile_image_url,
    role,
    is_approved,
    approval_status,
    is_active,
    created_at,
    updated_at
  FROM users
  ORDER BY created_at DESC;
$$;

-- Function to get pending users (bypassing RLS) 
CREATE OR REPLACE FUNCTION get_pending_users_admin()
RETURNS TABLE(
  id UUID,
  email TEXT,
  username TEXT,
  display_name TEXT,
  full_name TEXT,
  phone TEXT,
  address TEXT,
  user_type TEXT,
  parent_name TEXT,
  student_name TEXT,
  profile_image_url TEXT,
  role TEXT,
  is_approved BOOLEAN,
  approval_status TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    id,
    email,
    username,
    display_name,
    full_name,
    phone,
    address,
    user_type,
    parent_name,
    student_name,
    profile_image_url,
    role,
    is_approved,
    approval_status,
    is_active,
    created_at,
    updated_at
  FROM users
  WHERE is_approved = false
  ORDER BY created_at DESC;
$$;

-- Grant execute permissions to authenticated users (admin)
GRANT EXECUTE ON FUNCTION get_all_users_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_users_admin() TO authenticated;