"""
牌画像をzipから提供された新しいPNGに差し替えるスクリプト
-l (66x90, large) バージョンを使用
"""
from pathlib import Path
import base64
import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

img_dir = Path(r"C:\Users\haman\Downloads\チンイツ\pai-images\pai-images")
html_path = Path(r"C:\Users\haman\Downloads\チンイツ\chinitsu_trainer_v2.html")

# マッピング: IMGSキー → 画像ファイル名
mapping = {}
for n in range(1, 10):
    mapping[f"m{n}"] = f"man{n}-66-90-l.png"
    mapping[f"p{n}"] = f"pin{n}-66-90-l.png"
    mapping[f"s{n}"] = f"sou{n}-66-90-l.png"

# 新しいbase64データを生成
new_base64 = {}
for key, filename in mapping.items():
    filepath = img_dir / filename
    if not filepath.exists():
        print(f"❌ ファイルが見つかりません: {filepath}")
        sys.exit(1)
    with open(filepath, 'rb') as f:
        data = base64.b64encode(f.read()).decode('ascii')
    new_base64[key] = f"data:image/png;base64,{data}"
    print(f"  ✅ {key} ← {filename} ({len(data)} chars)")

# HTML読み込み
html = html_path.read_text(encoding='utf-8')

# IMGS オブジェクト内の各キーの値を置換
replaced = 0
for key, new_data_uri in new_base64.items():
    # パターン: "m1":"data:image/png;base64,..." (次の " まで)
    pattern = f'"{key}":"data:image/png;base64,[A-Za-z0-9+/=]+"'
    replacement = f'"{key}":"{new_data_uri}"'

    matches = re.findall(pattern, html)
    if len(matches) == 1:
        html = re.sub(pattern, replacement, html)
        replaced += 1
    elif len(matches) == 0:
        print(f"❌ パターン未検出: {key}")
    else:
        print(f"⚠️ 複数マッチ({len(matches)}): {key}")

# 書き出し
html_path.write_text(html, encoding='utf-8')
print(f"\n✅ {replaced}/{len(mapping)} 画像を差し替えました")

# ファイルサイズ確認
size_kb = html_path.stat().st_size / 1024
print(f"📄 HTMLファイルサイズ: {size_kb:.1f} KB")
