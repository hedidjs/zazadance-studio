# זזה דאנס - הוראות פריסה לשרת

## הבעיה הנוכחית
השרת שלך `zazadance.com/admin` לא מתעדכן אוטומטית מגיטהב.

## פתרונות מיידיים:

### פתרון 1: העלאה ידנית (מהיר)
1. הורד את הקובץ: `/Users/rontzarfati/Desktop/zazadance-admin-latest.zip`
2. חלץ את הקבצים
3. העלה את התוכן של תיקיית `web/` לתיקיית `/admin` בשרת שלך

### פתרון 2: הגדרת Webhook (פתרון קבוע)
1. העלה את הקובץ `deploy-webhook.php` לשרת שלך
2. בגיטהב, לך ל: Settings > Webhooks > Add webhook
3. הגדר:
   - Payload URL: `https://zazadance.com/deploy-webhook.php`
   - Content type: `application/json`
   - Secret: `zazadance-deploy-secret-2024`
   - Events: Just the push event

### פתרון 3: GitHub Actions (כבר מוגדר)
GitHub Actions כבר מוגדר ופועל. הקבצים מתעדכנים ב: `docs/admin/`

## הקבצים שנבנו:
- מערכת ניהול עדכונים מלאה
- עדכונים מקובעים (נעוץ למעלה)
- העלאת תמונות
- חיבור לסופבייס

## עדכון נוסף למסד הנתונים:
הוספתי עדכון בדיקה למסד הנתונים כדי לוודא שהמערכת עובדת.

## מצב נוכחי:
✅ הקוד מוכן ועובד
✅ GitHub Actions פועל
✅ עדכון נוסף למסד הנתונים
❌ השרת zazadance.com לא מושך עדכונים

**צריך להגדיר אחד מהפתרונות למעלה כדי שהשרת יתעדכן!**