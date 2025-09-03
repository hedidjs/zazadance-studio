# 🚀 Netlify Deployment Guide

## ⚠️ IMPORTANT: Static Deployment Only

This project is configured for **STATIC DEPLOYMENT** with pre-built files.

### ✅ Correct Netlify Settings:

#### Build Settings (MUST be empty):
- **Build command**: `(leave empty)`
- **Publish directory**: `user-app/build/web`

#### Advanced Settings:
- **Base directory**: `(leave empty)`

### 🚫 Do NOT set any build command in Netlify UI

The files are already built and included in the repository at:
- `user-app/build/web/` - User app (main site)
- `user-app/build/web/admin-build/` - Admin panel

### 🎯 Expected URLs after deployment:

- `https://your-domain.com` → User app
- `https://your-domain.com/admin` → Admin panel

### 🔧 If you need to rebuild:

Run locally:
```bash
./build.sh
git add -f user-app/build/web/
git commit -m "Update build"
git push
```

Then redeploy in Netlify.

### ❌ Common Issues:

1. **Build command not empty**: Remove any build command in Netlify settings
2. **Wrong publish directory**: Make sure it's `user-app/build/web`
3. **Missing files**: Ensure `user-app/build/web/` exists in the repository

### 📞 Support

If deployment fails, check:
1. Netlify build settings match above
2. Repository has the build files
3. No build command is set anywhere