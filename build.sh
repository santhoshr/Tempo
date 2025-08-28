#!/bin/bash

# Build script for Tempo Git Client
# Uses XcodeGen to generate the Xcode project from project.yml

set -e  # Exit on any error

echo "🔧 Building Tempo Git Client..."

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "📦 XcodeGen not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew is required to install XcodeGen"
        echo "   Install Homebrew from https://brew.sh/"
        exit 1
    fi
    brew install xcodegen
fi

# Generate Xcode project from project.yml
echo "🏗️  Generating Xcode project..."
xcodegen generate

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf ~/Library/Developer/Xcode/DerivedData/GitClient-*

# Build the project
echo "🔨 Building project..."
BUILD_OUTPUT=$(xcodebuild -project GitClient.xcodeproj -scheme GitClient -configuration Debug build 2>&1)
BUILD_STATUS=$?

echo "$BUILD_OUTPUT"

if [ $BUILD_STATUS -eq 0 ]; then
    echo "🎉 Build completed successfully!"
    
    # Extract the .app path from the lsregister command in build output
    echo "📦 Copying .app bundle..."
    APP_PATH=$(echo "$BUILD_OUTPUT" | grep "lsregister.*GitClient.app" | sed 's/.*lsregister -f -R -trusted //')
    
    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
        echo "🔍 Found .app at: $APP_PATH"
        
        # Remove existing .app if it exists
        if [ -d "./GitClient.app" ]; then
            rm -rf "./GitClient.app"
        fi
        
        # Copy the .app bundle to current directory
        cp -R "$APP_PATH" "./"
        echo "✅ GitClient.app copied to $(pwd)"
    else
        echo "⚠️  Could not extract .app path from build output"
    fi
else
    echo "❌ Build failed"
    exit 1
fi