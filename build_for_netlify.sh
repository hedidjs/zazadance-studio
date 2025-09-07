#!/bin/bash
set -e

echo "Building ZaZa Dance for Netlify..."

# Download and setup Flutter
echo "Setting up Flutter..."
if [ ! -d "flutter" ]; then
    echo "Downloading Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PWD/flutter/bin:$PATH"

# Configure Flutter
flutter config --no-analytics --enable-web
flutter doctor

# Create build directory
echo "Creating build directory..."
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