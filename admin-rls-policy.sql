-- Create admin policy for users table
-- This allows admin users to see all users regardless of approval status

-- First, create a policy that allows admin users to select all users
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
  auth.uid() = id  -- Users can still see their own records
);

-- Create a policy that allows admin users to update all users
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
  auth.uid() = id  -- Users can still update their own records
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

-- Create a policy that allows admin users to delete users
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