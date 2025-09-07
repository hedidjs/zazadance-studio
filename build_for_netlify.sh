#!/bin/bash
set -e

echo "Building ZaZa Dance for Netlify..."

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
    export PATH="/opt/flutter/bin:$PATH"
fi

# Ensure Flutter is up to date
flutter doctor

# Create build directory
rm -rf build
mkdir -p build

echo "Building user app..."
cd user-app
flutter pub get
flutter build web --release
cd ..

echo "Copying user app to build directory..."
cp -r user-app/build/web/* build/

echo "Building admin app..."
cd admin-app
flutter pub get
flutter build web --release
cd ..

echo "Copying admin app to build/admin directory..."
mkdir -p build/admin
cp -r admin-app/build/web/* build/admin/

echo "Adding redirects file..."
cat > build/_redirects << 'EOF'
# Netlify redirects for admin panel
/admin/* /admin/index.html 200
/* /index.html 200
EOF

echo "Build complete!"
ls -la build/
echo "Admin directory:"
ls -la build/admin/