#!/bin/bash
set -e

echo "🚀 Building ZaZa Dance for Netlify..."

# Error handling function
handle_error() {
    echo "❌ Error occurred in build step: $1"
    exit 1
}

# Download and setup Flutter
echo "📦 Setting up Flutter..."
if [ ! -d "flutter" ]; then
    echo "⬇️ Downloading Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 || handle_error "Flutter download failed"
    echo "✅ Flutter downloaded successfully"
fi

export PATH="$PWD/flutter/bin:$PATH"

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --no-analytics --enable-web || handle_error "Flutter config failed"

# Create build directory
echo "📁 Creating build directory..."
rm -rf build
mkdir -p build

echo "📝 Copying landing page..."
if [ ! -f "landing-page/index.html" ]; then
    handle_error "Landing page not found"
fi
cp landing-page/index.html build/ || handle_error "Failed to copy landing page"

# Copy favicon if it exists
if [ -f "landing-page/favicon.png" ]; then
    cp landing-page/favicon.png build/ || handle_error "Failed to copy favicon"
fi

echo "📝 Copying support page..."
if [ -f "support.html" ]; then
    cp support.html build/ || handle_error "Failed to copy support page"
    echo "✅ Support page copied successfully"
else
    echo "⚠️  Support page not found, skipping..."
fi

echo "✅ Landing page copied successfully"

echo "🔨 Building admin app..."
cd admin-app || handle_error "Failed to enter admin-app directory"

echo "📦 Getting admin app dependencies..."
flutter pub get || handle_error "Failed to get admin app dependencies"

echo "🏗️ Building admin app for web..."
flutter build web --release --verbose --base-href="/admin/" || handle_error "Failed to build admin app"

cd .. || handle_error "Failed to return to root directory"

echo "📋 Copying admin app to build/admin directory..."
mkdir -p build/admin || handle_error "Failed to create admin directory"
if [ ! -d "admin-app/build/web" ]; then
    handle_error "Admin app build directory not found"
fi
cp -r admin-app/build/web/* build/admin/ || handle_error "Failed to copy admin app"

echo "📝 Adding redirects file..."
cat > build/_redirects << 'EOF'
# Netlify redirects for admin panel
/admin/* /admin/index.html 200
# Support page redirect
/support /support.html 200
/* /index.html 200
EOF

echo "✅ Build complete!"
echo "📊 Build summary:"
echo "   - Landing page files: $(ls build/*.html | wc -l) HTML files"
echo "   - Admin app files: $(ls build/admin/ | wc -l) items"
echo "   - Total build size: $(du -sh build/)"

echo "🎉 ZaZa Dance deployment ready!"