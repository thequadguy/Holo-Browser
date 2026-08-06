from PIL import Image

image_path = "/Users/jake/.gemini/antigravity-ide/brain/23a36a63-5452-4cd8-9d31-9324a388414a/media__1785686579197.jpg"
output_path = "/Users/jake/Desktop/Holo Browser/Resources/AppIcon.png"

img = Image.open(image_path)
width, height = img.size

cx = width // 2
cy = (height // 2) - 20 # Shift up slightly

size = 760
left = cx - size // 2
top = cy - size // 2
right = cx + size // 2
bottom = cy + size // 2

cropped = img.crop((left, top, right, bottom))
resized = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
resized.save(output_path, "PNG")
print("Cropped and saved.")
