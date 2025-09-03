-- Create About Content table for dynamic content management
CREATE TABLE about_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title_he TEXT NOT NULL,
    title_en TEXT,
    content_he TEXT NOT NULL,
    content_en TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create RLS policies
ALTER TABLE about_content ENABLE ROW LEVEL SECURITY;

-- Allow read access for all authenticated users
CREATE POLICY "Allow read access for authenticated users" ON about_content
    FOR SELECT TO authenticated USING (is_active = true);

-- Allow full access for admin users (assuming there's an admin role)
CREATE POLICY "Allow admin full access" ON about_content
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Create indexes for performance
CREATE INDEX idx_about_content_active ON about_content(is_active, sort_order);
CREATE INDEX idx_about_content_sort ON about_content(sort_order);

-- Insert default content
INSERT INTO about_content (title_he, content_he, sort_order) VALUES 
(
    'ברוכים הבאים לסטודיו שרון לריקוד',
    'סטודיו שרון הוא מקום מיוחד בו החלום שלכם לרקוד הופך למציאות. אנחנו מציעים מגוון רחב של שיעורי ריקוד לכל הגילאים והרמות.

עם למעלה מ-10 שנות ניסיון בהוראת ריקוד, שרון מביאה אליכם את הידע, הניסיון והאהבה לריקוד. כל שיעור הוא חוויה ייחודית המותאמת לצרכים האישיים של כל תלמיד.

במה אנחנו מתמחים:
• בלט קלאסי לכל הגילאים
• ריקוד מודרני וקונטמפורארי  
• ג''אז ופאנק
• היפ הופ ורחוב
• הכנה לתחרויות ומבחני קבלה
• שיעורים פרטיים ובקבוצות קטנות

הסטודיו שלנו מצויד באולם מרווח עם רצפת פרקט מקצועית, קירות מראות ומערכת סאונד מתקדמת. כל זה כדי להעניק לכם את החוויה הטובה ביותר.

בואו להיות חלק מהמשפחה שלנו ולגלות את הקסם של הריקוד!',
    1
),
(
    'שרון - המייסדת והמורה הראשית',
    'שרון הוא בוגרת המחלקה לריקוד באוניברסיטה העברית ובעלת תואר במוסיקה מהאקדמיה למוסיקה בירושלים.

עם למעלה מ-15 שנות ניסיון בעולם הריקוד, שרון הקימה את הסטודיו ב-2018 מתוך חזון ליצור מקום בטוח ומעצים עבור רקדנים מכל הרמות.

ההכשרה המקצועית של שרון כוללת:
• תואר בריקוד - אוניברסיטה העברית
• הסמכה בבלט קלאסי - RAD (Royal Academy of Dance)
• הכשרה בריקוד מודרני - שיטת גרהם
• קורסי המשך במתודות הוראה מתקדמות

לאורך השנים הדריכה שרון מאות תלמידים, רבים מהם זכו בתחרויות ארציות והתקבלו לתוכניות יוקרתיות.

"הריקוד הוא השפה שבה הנשמה מתבטאת" - זהו המוטו של שרון, והיא מאמינה שכל אחד יכול למצוא את הביטוי שלו בריקוד.',
    2
),
(
    'המתקנים והציוד',
    'הסטודיו שלנו תוכנן במיוחד כדי לספק את התנאים האופטימליים ללמידה ותרגול ריקוד:

🏢 אולם הריקוד הראשי:
• שטח של 80 מ"ר
• רצפת פרקט מקצועית עם קפיצות אמצועיות
• קירות מראות בגובה מלא
• מזגן מרכזי למיזוג מושלם
• תאורה מקצועית עם עמעום

🎵 מערכת הסאונד:
• מערכת סטריאו מקצועית 
• מיקרופונים אלחוטיים
• חיבור Bluetooth ו-AUX
• בקרת עוצמה נפרדת לכל אזור

🚿 שירותים ומתלבשים:
• חדרי הלבשה נפרדים לגברים ונשים
• לוקרים אישיים לחפצי ערך
• מקלחות עם מים חמים
• אזור ישיבה מרווח

☕ אזור המתנה:
• ספות נוחות להורים המחכים
• פינת קפה וכיבוד קל
• WiFi חופשי
• חניה חופשיה בשפע

כל המתקנים שלנו עוברים ניקוי וחיטוי יומיים כדי להבטיח סביבה בטוחה ונעימה לכולם.',
    3
);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_about_content_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER about_content_updated_at
    BEFORE UPDATE ON about_content
    FOR EACH ROW
    EXECUTE FUNCTION update_about_content_updated_at();

-- Add helpful comment
COMMENT ON TABLE about_content IS 'Dynamic content for About Studio page - managed through admin panel';