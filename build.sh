#!/bin/bash

echo "🚀 Building ZaZa Dance Studio Apps for Production..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📦 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

print_status "Checking Flutter doctor..."
flutter doctor

# Build user app
print_status "Building User App..."
cd user-app

if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found in user-app directory"
    exit 1
fi

flutter clean
flutter pub get
flutter build web --release --base-href /

if [ $? -eq 0 ]; then
    print_success "User app built successfully!"
else
    print_error "Failed to build user app"
    exit 1
fi

cd ..

# Build admin app
print_status "Building Admin App..."
cd admin-app

if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found in admin-app directory"
    exit 1
fi

flutter clean
flutter pub get
flutter build web --release --base-href /admin/

if [ $? -eq 0 ]; then
    print_success "Admin app built successfully!"
else
    print_error "Failed to build admin app"
    exit 1
fi

cd ..

# Copy admin build to user app build directory
print_status "Combining builds..."

# Create admin directory in user app
mkdir -p user-app/build/web/admin

# Copy all admin build files
cp -r admin-app/build/web/* user-app/build/web/admin/

print_success "Build process completed successfully!"
print_status "Build output is in: user-app/build/web/"
print_status "User app: user-app/build/web/"
print_status "Admin app: user-app/build/web/admin/"

# Show build sizes
print_status "Build sizes:"
du -sh user-app/build/web/ | awk '{print "Total size: " $1}'
du -sh user-app/build/web/admin/ | awk '{print "Admin app size: " $1}'

echo ""
print_success "🎉 Ready for deployment to Netlify!"
echo "Upload the 'user-app/build/web/' directory to Netlify"