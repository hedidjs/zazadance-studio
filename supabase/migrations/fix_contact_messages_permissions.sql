-- Fix contact messages permissions for admin panel
-- This migration adds permissions for anonymous users to update contact message status
-- This is needed because the admin app has authentication issues and needs to work without login

-- Allow anonymous users to update contact messages (for admin debugging)
CREATE POLICY "Allow anon update for admin debugging" ON public.contact_messages 
FOR UPDATE 
TO anon 
USING (true) 
WITH CHECK (true);

-- Note: This policy should be reviewed for production use
-- Consider implementing proper authentication instead of allowing anonymous updates