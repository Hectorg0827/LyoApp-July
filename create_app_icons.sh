#!/bin/bash

echo "🎨 Creating App Icons for LyoApp"
echo "================================"

# Create a simple app icon using SF Symbols or basic design
# This creates a minimal but functional app icon for App Store submission

ICON_DIR="LyoApp/Assets.xcassets/AppIcon.appiconset"

# Create the base icon (you'll need to replace this with actual graphic design)
# For now, we'll create a placeholder that meets App Store requirements

echo "📱 Creating app icon files..."

# Create a simple icon generator script
cat > generate_app_icon.py << 'EOF'
#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont
import sys

def create_icon(size, filename):
    # Create a modern gradient background
    img = Image.new('RGB', (size, size), '#1a1a1a')
    draw = ImageDraw.Draw(img)
    
    # Create gradient effect
    for i in range(size):
        color_intensity = int(255 * (i / size))
        color = (color_intensity//3, color_intensity//2, color_intensity)
        draw.line([(0, i), (size, i)], fill=color)
    
    # Add the "L" for Lyo
    try:
        # Try to use a system font
        if size > 100:
            font_size = size // 2
        else:
            font_size = size // 3
            
        # Simple text overlay
        text = "L"
        text_size = size // 2
        x = (size - text_size) // 2
        y = (size - text_size) // 2
        
        # Draw white "L" in center
        draw.text((x, y), text, fill='white', stroke_width=2, stroke_fill='black')
        
    except Exception as e:
        print(f"Font error for size {size}: {e}")
        # Fallback: simple circle
        circle_size = size // 3
        circle_pos = (size // 2 - circle_size // 2, size // 2 - circle_size // 2)
        draw.ellipse([circle_pos[0], circle_pos[1], 
                     circle_pos[0] + circle_size, circle_pos[1] + circle_size], 
                     fill='white', outline='black', width=2)
    
    img.save(filename)
    print(f"✅ Created {filename} ({size}x{size})")

# Required iOS app icon sizes
icon_sizes = [
    (20, "icon_20pt.png"),
    (40, "icon_20pt@2x.png"),
    (60, "icon_20pt@3x.png"),
    (29, "icon_29pt.png"),
    (58, "icon_29pt@2x.png"),
    (87, "icon_29pt@3x.png"),
    (40, "icon_40pt.png"),
    (80, "icon_40pt@2x.png"),
    (120, "icon_40pt@3x.png"),
    (120, "icon_60pt@2x.png"),
    (180, "icon_60pt@3x.png"),
    (1024, "icon_1024pt.png")
]

print("🎨 Generating app icons...")
for size, filename in icon_sizes:
    create_icon(size, filename)

print("✅ All app icons generated!")
EOF

# Run the icon generator if Python and PIL are available
if command -v python3 >/dev/null && python3 -c "import PIL" 2>/dev/null; then
    echo "🐍 Python and PIL found, generating icons..."
    cd "$ICON_DIR"
    python3 ../../../generate_app_icon.py
    cd - > /dev/null
else
    echo "⚠️  Python/PIL not available, creating placeholder icons..."
    
    # Create simple placeholder files (you'll need to replace with actual icons)
    cd "$ICON_DIR"
    
    # Create empty placeholder files with correct names
    touch icon_20pt.png
    touch icon_20pt@2x.png
    touch icon_20pt@3x.png
    touch icon_29pt.png
    touch icon_29pt@2x.png
    touch icon_29pt@3x.png
    touch icon_40pt.png
    touch icon_40pt@2x.png
    touch icon_40pt@3x.png
    touch icon_60pt@2x.png
    touch icon_60pt@3x.png
    touch icon_1024pt.png
    
    echo "📝 Created placeholder icon files (need actual graphics)"
    cd - > /dev/null
fi

# Update Contents.json with proper file references
cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_20pt@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon_20pt@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "icon_29pt@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon_29pt@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "icon_40pt@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon_40pt@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon_60pt@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon_60pt@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon_20pt.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "icon_20pt@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon_29pt.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "icon_29pt@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon_40pt.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "icon_40pt@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon_1024pt.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Updated Contents.json with proper icon references"
echo ""
echo "🎯 Next steps:"
echo "1. Replace placeholder icons with actual Lyo-branded graphics"
echo "2. Use design tools like Figma, Sketch, or hire a designer"
echo "3. Ensure icons follow Apple's Human Interface Guidelines"
echo ""
echo "For now, the app has placeholder icons and can be built and tested."
