#!/bin/bash
set -e

echo "🚀 Installing Flutter for Netlify Build..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}📦 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
    print_success "Flutter is already installed!"
    flutter --version
    exit 0
fi

print_status "Flutter not found. Installing..."

# Install Flutter
FLUTTER_VERSION="3.24.0"
FLUTTER_ROOT="/opt/flutter"

# Download and extract Flutter
print_status "Downloading Flutter $FLUTTER_VERSION..."
cd /opt
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz
tar xf flutter.tar.xz
rm flutter.tar.xz

# Add Flutter to PATH
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Configure Flutter
print_status "Configuring Flutter..."
flutter config --no-analytics
flutter precache --web

print_success "Flutter $FLUTTER_VERSION installed successfully!"
flutter --version