"""画像サイズとバリエーションを確認"""
from pathlib import Path
from PIL import Image
import sys
sys.stdout.reconfigure(encoding='utf-8')

img_dir = Path(r"C:\Users\haman\Downloads\チンイツ\pai-images\pai-images")

# Check a few representative images
samples = [
    "man1-66-90-l.png", "man1-66-90-s.png",
    "pin1-66-90-l.png", "sou1-66-90-l.png",
    "man1-66-90-l-emb.png",
]

print("=== 画像サイズ確認 ===")
for name in samples:
    p = img_dir / name
    if p.exists():
        img = Image.open(p)
        print(f"  {name}: {img.size[0]}x{img.size[1]}px, mode={img.mode}, size={p.stat().st_size}bytes")

# List all unique prefixes
print("\n=== バリエーション ===")
prefixes = set()
for f in sorted(img_dir.glob("*.png")):
    parts = f.stem.split("-66-90-")
    if len(parts) == 2:
        prefixes.add(parts[0])

print(f"牌の種類: {sorted(prefixes)}")
print(f"合計: {len(prefixes)}種")

# Count variants per tile
variants = {}
for f in sorted(img_dir.glob("man1-*.png")):
    variants[f.name] = f.stat().st_size
print(f"\n=== man1のバリエーション ===")
for name, size in sorted(variants.items()):
    img = Image.open(img_dir / name)
    print(f"  {name}: {img.size[0]}x{img.size[1]}px ({size}bytes)")
