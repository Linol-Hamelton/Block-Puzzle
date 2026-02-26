import os
from PIL import Image, ImageDraw, ImageFont

# Конфигурация цветов и путей
BRAND_BG = "#1A1B26"  # Deep Twilight Blue
TEXT_COLOR = "#FFFFFF"
ACCENT_COLOR = "#7AA2F7"

ASSETS = [
    # 02_icons
    ("brand_pack/02_icons/app_icon_master_1024.png", (1024, 1024), BRAND_BG, "App Icon\nMaster"),
    ("brand_pack/02_icons/android_adaptive_foreground_1024.png", (1024, 1024), None, "Adaptive\nForeground"), # Transparent
    ("brand_pack/02_icons/android_adaptive_background_1024.png", (1024, 1024), BRAND_BG, "Adaptive\nBackground"),
    ("brand_pack/02_icons/web_favicon_512.png", (512, 512), BRAND_BG, "Favicon"),

    # 03_splash
    ("brand_pack/03_splash/splash_logo_light_1024.png", (1024, 1024), None, "Logo\nLight"),
    ("brand_pack/03_splash/splash_logo_dark_1024.png", (1024, 1024), None, "Logo\nDark"),
    ("brand_pack/03_splash/splash_bg_light.png", (1080, 1920), "#FFFFFF", "Splash BG\nLight"),
    ("brand_pack/03_splash/splash_bg_dark.png", (1080, 1920), BRAND_BG, "Splash BG\nDark"),

    # 04_store_google_play
    ("brand_pack/04_store_google_play/store_icon_512.png", (512, 512), BRAND_BG, "Store Icon"),
    ("brand_pack/04_store_google_play/feature_graphic_1024x500.png", (1024, 500), BRAND_BG, "Feature Graphic\n1024x500"),
    
    # 04_store_google_play screenshots (Placeholders)
    ("brand_pack/04_store_google_play/screenshots_phone/01_hook.png", (1080, 1920), BRAND_BG, "Screenshot 1\nHook"),
    ("brand_pack/04_store_google_play/screenshots_phone/02_satisfaction.png", (1080, 1920), BRAND_BG, "Screenshot 2\nCombo"),
    ("brand_pack/04_store_google_play/screenshots_phone/03_challenge.png", (1080, 1920), BRAND_BG, "Screenshot 3\nScore"),
    
    # 05_store_rustore
    ("brand_pack/05_store_rustore/store_icon_512.png", (512, 512), BRAND_BG, "Store Icon"),
]

def ensure_dir(file_path):
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        os.makedirs(directory)

def create_placeholder(path, size, bg_color, text):
    ensure_dir(path)
    
    # Создаем изображение (RGBA для прозрачности)
    if bg_color:
        img = Image.new('RGBA', size, color=bg_color)
    else:
        img = Image.new('RGBA', size, (0, 0, 0, 0)) # Полностью прозрачный

    draw = ImageDraw.Draw(img)
    
    # Рисуем рамку
    w, h = size
    draw.rectangle([(0, 0), (w-1, h-1)], outline=ACCENT_COLOR, width=5)
    
    # Рисуем диагонали для обозначения плейсхолдера
    draw.line([(0, 0), (w, h)], fill=ACCENT_COLOR, width=2)
    draw.line([(0, h), (w, 0)], fill=ACCENT_COLOR, width=2)

    # Пытаемся загрузить шрифт, иначе используем дефолтный
    try:
        # Попытка найти системный шрифт (может отличаться в зависимости от ОС)
        font = ImageFont.truetype("arial.ttf", size=int(min(w, h)/10))
    except IOError:
        font = ImageFont.load_default()

    # Рисуем текст по центру
    # Используем textbbox для Pillow >= 9.2.0, иначе textsize
    try:
        left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
        text_w = right - left
        text_h = bottom - top
    except AttributeError:
         text_w, text_h = draw.textsize(text, font=font)

    text_x = (w - text_w) / 2
    text_y = (h - text_h) / 2
    
    # Тень текста
    draw.text((text_x+2, text_y+2), text, font=font, fill="#000000")
    draw.text((text_x, text_y), text, font=font, fill=TEXT_COLOR, align="center")

    img.save(path)
    print(f"Created: {path}")

if __name__ == "__main__":
    print("Generating placeholder assets...")
    for path, size, bg, text in ASSETS:
        create_placeholder(path, size, bg, text)
    print("Done! Run 'pip install Pillow' if script fails.")