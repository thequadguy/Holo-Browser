import os
import subprocess
import json

master_image = "/Users/jake/.gemini/antigravity-ide/brain/fb6a43f9-c6e1-49bd-b6bc-8299b10d00a0/holo_app_icon_master_1785950500756.png"

appiconset_dir = "/Users/jake/Desktop/Holo Browser/HoloBrowser/Sources/App/Assets.xcassets/AppIcon.appiconset"
iconset_dir = "/Users/jake/Desktop/Holo Browser/Resources/AppIcon.iconset"
resources_appiconset = "/Users/jake/Desktop/Holo Browser/Resources/AppIcon.appiconset"

for d in [appiconset_dir, iconset_dir, resources_appiconset]:
    os.makedirs(d, exist_ok=True)

icon_sizes = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

contents_json = {
    "images": [
        {"idiom": "mac", "size": "16x16", "scale": "1x", "filename": "icon_16x16.png"},
        {"idiom": "mac", "size": "16x16", "scale": "2x", "filename": "icon_16x16@2x.png"},
        {"idiom": "mac", "size": "32x32", "scale": "1x", "filename": "icon_32x32.png"},
        {"idiom": "mac", "size": "32x32", "scale": "2x", "filename": "icon_32x32@2x.png"},
        {"idiom": "mac", "size": "128x128", "scale": "1x", "filename": "icon_128x128.png"},
        {"idiom": "mac", "size": "128x128", "scale": "2x", "filename": "icon_128x128@2x.png"},
        {"idiom": "mac", "size": "256x256", "scale": "1x", "filename": "icon_256x256.png"},
        {"idiom": "mac", "size": "256x256", "scale": "2x", "filename": "icon_256x256@2x.png"},
        {"idiom": "mac", "size": "512x512", "scale": "1x", "filename": "icon_512x512.png"},
        {"idiom": "mac", "size": "512x512", "scale": "2x", "filename": "icon_512x512@2x.png"},
    ],
    "info": {
        "version": 1,
        "author": "antigravity"
    }
}

for d in [appiconset_dir, resources_appiconset]:
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump(contents_json, f, indent=2)

for filename, size in icon_sizes:
    for target_dir in [appiconset_dir, iconset_dir, resources_appiconset]:
        target_path = os.path.join(target_dir, filename)
        cmd = f'sips -s format png -z {size} {size} "{master_image}" --out "{target_path}" > /dev/null'
        subprocess.run(cmd, shell=True, check=True)

# Generate AppIcon.icns from .iconset using iconutil
icns_target = "/Users/jake/Desktop/Holo Browser/Resources/AppIcon.icns"
cmd_icns = f'iconutil -c icns "{iconset_dir}" -o "{icns_target}"'
subprocess.run(cmd_icns, shell=True, check=True)

# Copy AppIcon.icns into Holo Browser.app bundle resources
bundle_icns = "/Users/jake/Desktop/Holo Browser.app/Contents/Resources/AppIcon.icns"
subprocess.run(f'cp "{icns_target}" "{bundle_icns}"', shell=True, check=True)

print("✅ AppIcon.appiconset & AppIcon.icns successfully generated and installed into Holo Browser.app bundle!")
