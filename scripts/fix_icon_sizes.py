#!/usr/bin/env python3
"""
Fix existing icon images to comply with Android Adaptive Icon guidelines.
This script resizes and repositions icons to fit the 60-66% canvas guideline
without changing the image content.

Requirements: pip install Pillow
"""

from PIL import Image, ImageDraw
import os

# Target icon size: 60-66% of canvas (using 65% = 665px)
CANVAS_SIZE = 1024
TARGET_ICON_SIZE = int(CANVAS_SIZE * 0.65)  # 665px (65% of 1024)
PADDING = (CANVAS_SIZE - TARGET_ICON_SIZE) // 2  # ~180px padding on each side

def fix_foreground(input_path, output_path):
    """Fix foreground icon: resize to fit 60-66% guideline with padding"""
    print(f"  Fixing {os.path.basename(input_path)}...")
    
    # Load original image
    original = Image.open(input_path).convert('RGBA')
    orig_width, orig_height = original.size
    
    # Create new canvas with transparent background
    canvas = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    
    # Calculate scaling to fit target size
    # Use the larger dimension to determine scale
    scale = min(TARGET_ICON_SIZE / orig_width, TARGET_ICON_SIZE / orig_height)
    new_width = int(orig_width * scale)
    new_height = int(orig_height * scale)
    
    # Resize image maintaining aspect ratio
    resized = original.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Center the resized image on canvas
    x_offset = (CANVAS_SIZE - new_width) // 2
    y_offset = (CANVAS_SIZE - new_height) // 2
    
    # Paste resized image onto canvas
    canvas.paste(resized, (x_offset, y_offset), resized)
    
    # Save
    canvas.save(output_path, 'PNG')
    print(f"    Original: {orig_width}x{orig_height}, New: {new_width}x{new_height} (centered on {CANVAS_SIZE}x{CANVAS_SIZE})")
    print(f"    Padding: {x_offset}px on each side")

def fix_monochrome(input_path, output_path):
    """Fix monochrome icon: ensure pure white, transparent background, proper sizing"""
    print(f"  Fixing {os.path.basename(input_path)}...")
    
    # Load original image
    original = Image.open(input_path).convert('RGBA')
    orig_width, orig_height = original.size
    
    # Create new canvas with transparent background
    canvas = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    
    # Convert to pure white (if not already)
    # Extract alpha channel
    alpha = original.split()[3]
    
    # Create pure white version using alpha as mask
    white_image = Image.new('RGBA', (orig_width, orig_height), (255, 255, 255, 255))
    white_image.putalpha(alpha)
    
    # Calculate scaling to fit target size
    scale = min(TARGET_ICON_SIZE / orig_width, TARGET_ICON_SIZE / orig_height)
    new_width = int(orig_width * scale)
    new_height = int(orig_height * scale)
    
    # Resize image maintaining aspect ratio
    resized = white_image.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Center the resized image on canvas
    x_offset = (CANVAS_SIZE - new_width) // 2
    y_offset = (CANVAS_SIZE - new_height) // 2
    
    # Paste resized image onto canvas
    canvas.paste(resized, (x_offset, y_offset), resized)
    
    # Save
    canvas.save(output_path, 'PNG')
    print(f"    Converted to pure white, resized to {new_width}x{new_height} (centered on {CANVAS_SIZE}x{CANVAS_SIZE})")

def fix_background(input_path, output_path):
    """Fix background icon: ensure solid color/gradient, proper size"""
    print(f"  Fixing {os.path.basename(input_path)}...")
    
    # Load original image
    original = Image.open(input_path).convert('RGB')
    orig_width, orig_height = original.size
    
    # Resize to canvas size if needed
    if orig_width != CANVAS_SIZE or orig_height != CANVAS_SIZE:
        resized = original.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)
        resized.save(output_path, 'PNG')
        print(f"    Resized from {orig_width}x{orig_height} to {CANVAS_SIZE}x{CANVAS_SIZE}")
    else:
        original.save(output_path, 'PNG')
        print(f"    Already correct size ({CANVAS_SIZE}x{CANVAS_SIZE})")

def main():
    """Fix all icon files"""
    print("Fixing icon files to comply with Android Adaptive Icon guidelines...")
    print(f"Target: Icon occupies ~{int((TARGET_ICON_SIZE/CANVAS_SIZE)*100)}% of canvas ({TARGET_ICON_SIZE}px) with padding\n")
    
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Create backup directory
    backup_dir = os.path.join(script_dir, 'backup')
    os.makedirs(backup_dir, exist_ok=True)
    
    # Files to fix
    files_to_fix = [
        ('ic_launcher_foreground.png', fix_foreground),
        ('ic_launcher_monochrome.png', fix_monochrome),
        ('ic_launcher_background.png', fix_background),
    ]
    
    for filename, fix_func in files_to_fix:
        input_path = os.path.join(script_dir, filename)
        output_path = os.path.join(script_dir, filename)
        backup_path = os.path.join(backup_dir, filename)
        
        if not os.path.exists(input_path):
            print(f"  ⚠️  {filename} not found, skipping...")
            continue
        
        # Backup original
        backup_img = Image.open(input_path)
        backup_img.save(backup_path)
        print(f"  Backed up to {os.path.join('backup', filename)}")
        
        # Fix the icon
        fix_func(input_path, output_path)
        print()
    
    print("[SUCCESS] All icon files fixed!")
    print(f"\nOriginal files backed up to: {backup_dir}")
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
        import traceback
        traceback.print_exc()
        exit(1)

