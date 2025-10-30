#!/bin/bash

# WeChat Keyboard Swipe - Environment Check Script
# 微信键盘滑动切换输入法 - 环境检查脚本

echo "==========================================="
echo "Environment Check | 环境检查"
echo "==========================================="
echo ""

EXIT_CODE=0

# 检查THEOS环境变量
echo "→ Checking THEOS environment variable..."
if [ -z "$THEOS" ]; then
    echo "  ❌ THEOS is not set"
    echo "     Please run: export THEOS=~/theos"
    echo "     And add to ~/.bashrc: echo 'export THEOS=~/theos' >> ~/.bashrc"
    EXIT_CODE=1
else
    echo "  ✓ THEOS is set to: $THEOS"
    
    if [ ! -d "$THEOS" ]; then
        echo "  ❌ THEOS directory does not exist: $THEOS"
        echo "     Please install Theos: git clone --recursive https://github.com/theos/theos.git $THEOS"
        EXIT_CODE=1
    else
        echo "  ✓ THEOS directory exists"
    fi
fi
echo ""

# 检查Theos makefiles
echo "→ Checking Theos makefiles..."
if [ -d "$THEOS/makefiles" ]; then
    echo "  ✓ Theos makefiles found"
else
    echo "  ❌ Theos makefiles not found"
    echo "     Theos may not be installed correctly"
    EXIT_CODE=1
fi
echo ""

# 检查SDK
echo "→ Checking iOS SDK..."
if [ -d "$THEOS/sdks" ]; then
    SDK_COUNT=$(find "$THEOS/sdks" -maxdepth 1 -name "iPhoneOS*.sdk" -type d | wc -l)
    if [ $SDK_COUNT -gt 0 ]; then
        echo "  ✓ Found $SDK_COUNT iOS SDK(s):"
        find "$THEOS/sdks" -maxdepth 1 -name "iPhoneOS*.sdk" -type d -exec basename {} \;
    else
        echo "  ❌ No iOS SDK found in $THEOS/sdks"
        echo "     Please download SDK from: https://github.com/theos/sdks"
        EXIT_CODE=1
    fi
else
    echo "  ❌ SDK directory not found: $THEOS/sdks"
    EXIT_CODE=1
fi
echo ""

# 检查工具链
echo "→ Checking toolchain..."
if [ -d "$THEOS/toolchain" ]; then
    echo "  ✓ Toolchain directory exists"
    
    # Linux特定检查
    if [ "$(uname)" = "Linux" ]; then
        if [ -d "$THEOS/toolchain/linux/iphone" ]; then
            echo "  ✓ Linux iOS toolchain found"
        else
            echo "  ⚠️  Linux iOS toolchain not found"
            echo "     You may need to install it for cross-compilation"
            echo "     See: LINUX_BUILD_GUIDE.md"
        fi
    fi
else
    echo "  ⚠️  Toolchain directory not found"
    echo "     May need manual installation for some platforms"
fi
echo ""

# 检查必要工具
echo "→ Checking required tools..."

check_tool() {
    if command -v $1 &> /dev/null; then
        echo "  ✓ $1 found: $(command -v $1)"
    else
        echo "  ❌ $1 not found"
        echo "     Please install: $2"
        EXIT_CODE=1
    fi
}

check_tool "make" "sudo apt install build-essential"
check_tool "clang" "sudo apt install clang"
check_tool "git" "sudo apt install git"
check_tool "perl" "sudo apt install perl"
echo ""

# 检查项目文件
echo "→ Checking project files..."
PROJECT_FILES=("Tweak.x" "Makefile" "control" "WeChatKeyboardSwipe.plist")
ALL_FILES_EXIST=true

for file in "${PROJECT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ❌ $file not found"
        ALL_FILES_EXIST=false
        EXIT_CODE=1
    fi
done

if [ "$ALL_FILES_EXIST" = false ]; then
    echo ""
    echo "  ⚠️  Some project files are missing"
    echo "     Make sure you're in the project root directory"
fi
echo ""

# 检查网络连接（可选）
echo "→ Checking network connectivity (optional)..."
if ping -c 1 github.com &> /dev/null; then
    echo "  ✓ Network connection OK"
else
    echo "  ⚠️  Cannot reach github.com"
    echo "     Network may be required for first-time setup"
fi
echo ""

# 总结
echo "==========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ All checks passed!"
    echo ""
    echo "You're ready to build. Run:"
    echo "  make clean package"
    echo ""
    echo "Or use the build script:"
    echo "  ./build.sh"
else
    echo "❌ Some checks failed"
    echo ""
    echo "Please fix the issues above before building."
    echo ""
    echo "For detailed setup instructions, see:"
    echo "  - README.md"
    echo "  - LINUX_BUILD_GUIDE.md (for Linux)"
    echo "  - QUICKSTART.md"
fi
echo "==========================================="

exit $EXIT_CODE
