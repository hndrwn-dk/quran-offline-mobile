#!/usr/bin/env python3
"""
Copy monochrome icon to Android mipmap folders for Material You themed icons.
This script generates ic_launcher_monochrome.png in all required mipmap folders.

Requirements: pip install Pillow
"""

from PIL import Image
import os
import shutil

# Android mipmap density folders and their sizes
MIPMAP_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

def copy_monochrome_icon():
    """Copy and resize monochrome icon to all mipmap folders"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    
    source_icon = os.path.join(script_dir, 'ic_launcher_monochrome.png')
    android_res = os.path.join(project_root, 'android', 'app', 'src', 'main', 'res')
    
    if not os.path.exists(source_icon):
        print(f"Error: {source_icon} not found!")
        return False
    
    print("Copying monochrome icon to mipmap folders...")
    
    # Load source icon
    source_img = Image.open(source_icon).convert('RGBA')
    
    for folder_name, size in MIPMAP_SIZES.items():
        folder_path = os.path.join(android_res, folder_name)
        os.makedirs(folder_path, exist_ok=True)
        
        output_path = os.path.join(folder_path, 'ic_launcher_monochrome.png')
        
        # Resize icon to required size
        resized = source_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(output_path, 'PNG')
        
        print(f"  Created {folder_name}/ic_launcher_monochrome.png ({size}x{size}px)")
    
    print("\n[SUCCESS] Monochrome icons copied to all mipmap folders!")
    return True

if __name__ == '__main__':
    try:
        if copy_monochrome_icon():
            print("\nNext: Rebuild the app to verify the monochrome icon works.")
    except ImportError:
        print("Error: Pillow is required. Install it with:")
        print("  pip install Pillow")
        exit(1)
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

