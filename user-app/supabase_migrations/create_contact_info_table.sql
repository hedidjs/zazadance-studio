-- Create contact_info table for dance studio contact information
-- Migration: create_contact_info_table.sql

CREATE TABLE IF NOT EXISTS contact_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone TEXT,
    email TEXT,
    address TEXT,
    working_hours TEXT,
    whatsapp_number TEXT,
    instagram_username TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create an updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at column
CREATE TRIGGER update_contact_info_updated_at
    BEFORE UPDATE ON contact_info
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE contact_info IS 'Stores contact information for the dance studio';
COMMENT ON COLUMN contact_info.id IS 'Primary key, UUID generated automatically';
COMMENT ON COLUMN contact_info.phone IS 'Primary phone number';
COMMENT ON COLUMN contact_info.email IS 'Primary email address';
COMMENT ON COLUMN contact_info.address IS 'Physical address of the studio';
COMMENT ON COLUMN contact_info.working_hours IS 'Operating hours information';
COMMENT ON COLUMN contact_info.whatsapp_number IS 'WhatsApp contact number';
COMMENT ON COLUMN contact_info.instagram_username IS 'Instagram account username';
COMMENT ON COLUMN contact_info.is_active IS 'Whether this contact info is currently active';
COMMENT ON COLUMN contact_info.created_at IS 'Timestamp when record was created';
COMMENT ON COLUMN contact_info.updated_at IS 'Timestamp when record was last updated';

-- Insert initial record with current data
INSERT INTO contact_info (phone, email, address, working_hours, whatsapp_number, instagram_username)
VALUES (
    '052-727-4321',
    'sharon.art6263@gmail.com',
    'השקד 68, בית עזרא',
    'ימים א''-ה'' 11:00-19:00',
    '0527274321',
    'studio_sharon'
) ON CONFLICT DO NOTHING;