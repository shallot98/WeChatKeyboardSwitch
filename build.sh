#!/bin/bash

# WeChat Keyboard Swipe - Build Script
# 微信键盘滑动切换输入法 - 编译脚本

set -e

echo "======================================"
echo "WeChat Keyboard Swipe - Build Script"
echo "======================================"
echo ""

# Check if THEOS is set
if [ -z "$THEOS" ]; then
    echo "❌ Error: THEOS environment variable is not set."
    echo "Please set THEOS to your Theos installation directory."
    echo "Example: export THEOS=~/theos"
    exit 1
fi

echo "✓ THEOS found at: $THEOS"
echo ""

# Check if we're in the right directory
if [ ! -f "Tweak.x" ] || [ ! -f "Makefile" ]; then
    echo "❌ Error: Tweak.x or Makefile not found."
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "Building the tweak..."
echo ""

# Clean previous build
echo "→ Cleaning previous build..."
make clean || true

# Build the package
echo "→ Building package..."
make package

echo ""
echo "======================================"
echo "✓ Build completed successfully!"
echo ""

# Find the generated .deb file
DEB_FILE=$(find packages -name "*.deb" -type f | head -n 1)

if [ -n "$DEB_FILE" ]; then
    echo "📦 Package created: $DEB_FILE"
    echo ""
    
    # Display file info
    ls -lh "$DEB_FILE"
    echo ""
    
    echo "To install on your device:"
    echo "1. Copy the .deb file to your device"
    echo "   scp $DEB_FILE root@<device-ip>:/var/root/"
    echo ""
    echo "2. SSH into your device and install"
    echo "   ssh root@<device-ip>"
    echo "   dpkg -i /var/root/$(basename $DEB_FILE)"
    echo "   killall -9 WeChat"
    echo ""
    echo "Or use: make package install THEOS_DEVICE_IP=<your-device-ip>"
else
    echo "⚠️  Warning: .deb file not found in packages directory"
fi

echo "======================================"
