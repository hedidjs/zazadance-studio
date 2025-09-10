
# ZaZa Dance - Build 31
# תאריך: 2025-09-10 02:13:20

הקוד המתוקן כולל:

✅ Google Sign-In OAuth Fix (lib/services/google_auth_service.dart:65-67)
- החלפה מ-signInWithIdToken ל-signInWithOAuth
- הסרת serverClientId הבעייתי
- מנגנון fallback מתקדם

✅ Delete Account Button (lib/features/profile/profile_simple_screen.dart:510-580)  
- כפתור אדום בולט עם double confirmation
- מחיקה מלאה של נתוני משתמש ותמונות
- איזור "מסוכן" עם אזהרות

✅ Database Table Fix (lib/services/google_auth_service.dart:169)
- תיקון הפניה מטבלת profiles ל-users  
- פתרון PostgreSQL "table not found" error

גרסה: 2.0.0+31
סטטוס: מוכן להעלאה
