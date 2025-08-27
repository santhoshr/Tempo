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
if xcodebuild -project GitClient.xcodeproj -scheme GitClient -configuration Debug build; then
    echo "🎉 Build completed successfully!"
else
    echo "❌ Build failed"
    exit 1
fi