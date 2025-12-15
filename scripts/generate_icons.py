#!/usr/bin/env python3
"""
Generate PNG icon files for Quran Offline app.
Requires: pip install Pillow
"""

from PIL import Image, ImageDraw
import os

# Colors (Material You green scheme)
GREEN_PRIMARY = (76, 175, 80)  # #4CAF50
GREEN_DARK = (46, 125, 50)     # #2E7D32
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

def create_background():
    """Create ic_launcher_background.png - solid green background"""
    img = Image.new('RGB', (1024, 1024), GREEN_PRIMARY)
    return img

def create_app_icon():
    """Create app_icon_1024.png - full icon with background"""
    img = Image.new('RGB', (1024, 1024), GREEN_PRIMARY)
    draw = ImageDraw.Draw(img)
    
    # Draw rounded corners effect (subtle)
    # Draw book icon
    center_x, center_y = 512, 512
    
    # Book dimensions
    book_width = 400
    book_height = 560
    book_x = center_x - book_width // 2
    book_y = center_y - book_height // 2
    
    # Left page
    draw.rectangle(
        [book_x, book_y, book_x + book_width // 2, book_y + book_height],
        fill=WHITE,
        outline=None
    )
    
    # Right page
    draw.rectangle(
        [book_x + book_width // 2, book_y, book_x + book_width, book_y + book_height],
        fill=WHITE,
        outline=None
    )
    
    # Book spine
    draw.rectangle(
        [book_x, book_y, book_x + 8, book_y + book_height],
        fill=GREEN_DARK,
        outline=None
    )
    
    # Text lines (left page)
    line_spacing = 100
    for i in range(5):
        y = book_y + 120 + (i * line_spacing)
        draw.line(
            [book_x + 20, y, book_x + book_width // 2 - 20, y],
            fill=GREEN_PRIMARY,
            width=3
        )
    
    # Text lines (right page)
    for i in range(5):
        y = book_y + 120 + (i * line_spacing)
        draw.line(
            [book_x + book_width // 2 + 20, y, book_x + book_width - 20, y],
            fill=GREEN_PRIMARY,
            width=3
        )
    
    return img

def create_foreground():
    """Create ic_launcher_foreground.png - transparent background with mihrab + book icon
    Icon should occupy ~60-66% of canvas with padding around edges"""
    img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))  # Transparent
    draw = ImageDraw.Draw(img)
    
    center_x, center_y = 512, 512
    
    # Icon should be ~60-66% of canvas (614-676px), with padding
    # Use 65% = 665px for main icon area
    icon_size = 665
    icon_x = center_x - icon_size // 2
    icon_y = center_y - icon_size // 2
    
    # Draw mihrab arch (pointed arch shape) - occupies most of icon area
    arch_width = int(icon_size * 0.7)  # 70% of icon size
    arch_height = int(icon_size * 0.5)  # 50% of icon size
    arch_center_x = center_x
    arch_center_y = center_y
    arch_left = arch_center_x - arch_width // 2
    arch_right = arch_center_x + arch_width // 2
    arch_top = arch_center_y - arch_height // 2
    arch_bottom = arch_center_y + arch_height // 2
    
    # Create pointed arch path (mihrab shape)
    arch_points = [
        (arch_left, arch_bottom),  # Bottom left
        (arch_left, arch_top + int(arch_height * 0.6)),  # Left side
        (arch_center_x, arch_top - int(arch_height * 0.1)),  # Top point
        (arch_right, arch_top + int(arch_height * 0.6)),  # Right side
        (arch_right, arch_bottom),  # Bottom right
    ]
    draw.polygon(arch_points, fill=(46, 125, 50, 255))  # Dark green
    
    # Book inside arch - smaller, centered
    book_width = int(icon_size * 0.35)  # 35% of icon size
    book_height = int(icon_size * 0.25)  # 25% of icon size
    book_x = center_x - book_width // 2
    book_y = center_y - book_height // 2
    
    # Left page
    draw.rectangle(
        [book_x, book_y, book_x + book_width // 2, book_y + book_height],
        fill=(255, 255, 255, 242),  # 95% opacity white
        outline=None
    )
    
    # Right page
    draw.rectangle(
        [book_x + book_width // 2, book_y, book_x + book_width, book_y + book_height],
        fill=(255, 255, 255, 242),
        outline=None
    )
    
    # Book spine
    draw.rectangle(
        [book_x, book_y, book_x + 6, book_y + book_height],
        fill=(46, 125, 50, 255),  # Dark green
        outline=None
    )
    
    return img

def create_monochrome():
    """Create ic_launcher_monochrome.png - pure white icon on transparent background
    For Material You themed icons. Thinner strokes than foreground."""
    img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))  # Transparent
    draw = ImageDraw.Draw(img)
    
    center_x, center_y = 512, 512
    
    # Icon should be ~60-66% of canvas, same as foreground
    icon_size = 665
    icon_x = center_x - icon_size // 2
    icon_y = center_y - icon_size // 2
    
    # Draw mihrab arch - thinner strokes, pure white
    arch_width = int(icon_size * 0.7)
    arch_height = int(icon_size * 0.5)
    arch_center_x = center_x
    arch_center_y = center_y
    arch_left = arch_center_x - arch_width // 2
    arch_right = arch_center_x + arch_width // 2
    arch_top = arch_center_y - arch_height // 2
    arch_bottom = arch_center_y + arch_height // 2
    
    # Create pointed arch path (mihrab shape) - pure white
    arch_points = [
        (arch_left, arch_bottom),
        (arch_left, arch_top + int(arch_height * 0.6)),
        (arch_center_x, arch_top - int(arch_height * 0.1)),
        (arch_right, arch_top + int(arch_height * 0.6)),
        (arch_right, arch_bottom),
    ]
    draw.polygon(arch_points, fill=(255, 255, 255, 255))  # Pure white
    
    # Book inside arch - smaller, thinner
    book_width = int(icon_size * 0.35)
    book_height = int(icon_size * 0.25)
    book_x = center_x - book_width // 2
    book_y = center_y - book_height // 2
    
    # Left page - pure white, slightly transparent for depth
    draw.rectangle(
        [book_x, book_y, book_x + book_width // 2, book_y + book_height],
        fill=(255, 255, 255, 240),  # Slightly transparent white
        outline=None
    )
    
    # Right page
    draw.rectangle(
        [book_x + book_width // 2, book_y, book_x + book_width, book_y + book_height],
        fill=(255, 255, 255, 240),
        outline=None
    )
    
    # Book spine - pure white, thinner
    draw.rectangle(
        [book_x, book_y, book_x + 4, book_y + book_height],  # Thinner (4px instead of 6px)
        fill=(255, 255, 255, 255),  # Pure white
        outline=None
    )
    
    return img

def main():
    """Generate all icon files"""
    print("Generating icon files...")
    
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Generate icons
    print("  Creating app_icon_1024.png...")
    app_icon = create_app_icon()
    app_icon.save(os.path.join(script_dir, 'app_icon_1024.png'), 'PNG')
    
    print("  Creating ic_launcher_background.png...")
    background = create_background()
    background.save(os.path.join(script_dir, 'ic_launcher_background.png'), 'PNG')
    
    print("  Creating ic_launcher_foreground.png...")
    foreground = create_foreground()
    foreground.save(os.path.join(script_dir, 'ic_launcher_foreground.png'), 'PNG')
    
    print("  Creating ic_launcher_monochrome.png...")
    monochrome = create_monochrome()
    monochrome.save(os.path.join(script_dir, 'ic_launcher_monochrome.png'), 'PNG')
    
    print("\n[SUCCESS] All icon files generated successfully!")
    print("\nNext step: Run 'dart run flutter_launcher_icons' to generate platform-specific icons.")

if __name__ == '__main__':
    try:
        main()
    except ImportError:
        print("Error: Pillow is required. Install it with:")
        print("  pip install Pillow")
        exit(1)
    except Exception as e:
        print(f"Error: {e}")
        exit(1)

