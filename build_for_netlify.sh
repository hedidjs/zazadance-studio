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

echo "🔨 Building user app..."
cd user-app || handle_error "Failed to enter user-app directory"

# Skip Flutter doctor - it's not critical for build
echo "📦 Getting user app dependencies..."
flutter pub get || handle_error "Failed to get user app dependencies"

echo "🏗️ Building user app for web..."
flutter build web --release --verbose || handle_error "Failed to build user app"

cd .. || handle_error "Failed to return to root directory"

echo "📋 Copying user app to build directory..."
if [ ! -d "user-app/build/web" ]; then
    handle_error "User app build directory not found"
fi
cp -r user-app/build/web/* build/ || handle_error "Failed to copy user app"

echo "🔨 Building admin app..."
cd admin-app || handle_error "Failed to enter admin-app directory"

echo "📦 Getting admin app dependencies..."
flutter pub get || handle_error "Failed to get admin app dependencies"

echo "🏗️ Building admin app for web..."
flutter build web --release --verbose || handle_error "Failed to build admin app"

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
/* /index.html 200
EOF

echo "✅ Build complete!"
echo "📊 Build summary:"
echo "   - User app files: $(ls build/ | wc -l) items"
echo "   - Admin app files: $(ls build/admin/ | wc -l) items"
echo "   - Total build size: $(du -sh build/)"

echo "🎉 ZaZa Dance deployment ready!"