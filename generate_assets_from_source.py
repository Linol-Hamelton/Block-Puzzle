from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parent
SOURCE_IMAGE = ROOT / "Gemini_Generated_Image_opo6faopo6faopo6.png"

# Coordinates tuned for source sheet size 2816x1536.
CROPS = {
    "app_icon_master": (34, 23, 535, 432),
    "android_adaptive_foreground": (600, 23, 1093, 432),
    "android_adaptive_background": (1166, 23, 1660, 432),
    "web_favicon": (1771, 23, 2174, 432),
    "splash_logo_light": (2331, 23, 2735, 432),
    "splash_logo_dark": (34, 539, 535, 943),
    "splash_bg_light": (600, 539, 1093, 943),
    "splash_bg_dark": (1166, 539, 1660, 943),
    "splash_bg_dark_with_logo": (1771, 539, 2174, 943),
    "store_icon_google": (2331, 539, 2735, 943),
    "feature_graphic": (34, 1050, 535, 1371),
    "screenshot_01": (600, 1050, 1093, 1400),
    "screenshot_02": (1166, 1050, 1660, 1400),
    "screenshot_03": (1771, 1050, 2174, 1400),
    "store_icon_rustore": (2331, 1050, 2735, 1371),
}


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save_fit(
    src: Image.Image,
    crop_box: tuple[int, int, int, int],
    out_path: Path,
    size: tuple[int, int],
    *,
    keep_alpha: bool = True,
) -> None:
    cropped = src.crop(crop_box)
    fitted = ImageOps.fit(cropped, size, method=Image.Resampling.LANCZOS)
    if not keep_alpha and fitted.mode == "RGBA":
        fitted = fitted.convert("RGB")
    ensure_parent(out_path)
    fitted.save(out_path)
    print(f"Generated: {out_path}")


def generate_brand_pack(src: Image.Image) -> None:
    outputs = [
        (CROPS["app_icon_master"], ROOT / "brand_pack/02_icons/app_icon_master_1024.png", (1024, 1024)),
        (
            CROPS["android_adaptive_foreground"],
            ROOT / "brand_pack/02_icons/android_adaptive_foreground_1024.png",
            (1024, 1024),
        ),
        (
            CROPS["android_adaptive_background"],
            ROOT / "brand_pack/02_icons/android_adaptive_background_1024.png",
            (1024, 1024),
        ),
        (CROPS["web_favicon"], ROOT / "brand_pack/02_icons/web_favicon_512.png", (512, 512)),
        (CROPS["splash_logo_light"], ROOT / "brand_pack/03_splash/splash_logo_light_1024.png", (1024, 1024)),
        (CROPS["splash_logo_dark"], ROOT / "brand_pack/03_splash/splash_logo_dark_1024.png", (1024, 1024)),
        (CROPS["splash_bg_light"], ROOT / "brand_pack/03_splash/splash_bg_light.png", (1080, 1920)),
        (CROPS["splash_bg_dark"], ROOT / "brand_pack/03_splash/splash_bg_dark.png", (1080, 1920)),
        (CROPS["store_icon_google"], ROOT / "brand_pack/04_store_google_play/store_icon_512.png", (512, 512)),
        (
            CROPS["feature_graphic"],
            ROOT / "brand_pack/04_store_google_play/feature_graphic_1024x500.png",
            (1024, 500),
        ),
        (
            CROPS["screenshot_01"],
            ROOT / "brand_pack/04_store_google_play/screenshots_phone/01_hook.png",
            (1080, 1920),
        ),
        (
            CROPS["screenshot_02"],
            ROOT / "brand_pack/04_store_google_play/screenshots_phone/02_satisfaction.png",
            (1080, 1920),
        ),
        (
            CROPS["screenshot_03"],
            ROOT / "brand_pack/04_store_google_play/screenshots_phone/03_challenge.png",
            (1080, 1920),
        ),
        (CROPS["store_icon_rustore"], ROOT / "brand_pack/05_store_rustore/store_icon_512.png", (512, 512)),
    ]

    for crop, out, size in outputs:
        save_fit(src, crop, out, size)


def apply_android_branding(src: Image.Image) -> None:
    # Launcher icons
    launcher_targets = [
        ("mipmap-mdpi/ic_launcher.png", 48),
        ("mipmap-hdpi/ic_launcher.png", 72),
        ("mipmap-xhdpi/ic_launcher.png", 96),
        ("mipmap-xxhdpi/ic_launcher.png", 144),
        ("mipmap-xxxhdpi/ic_launcher.png", 192),
    ]
    for rel, size in launcher_targets:
        out = ROOT / "apps/mobile/android/app/src/main/res" / rel
        save_fit(src, CROPS["app_icon_master"], out, (size, size))

    # Android launch image (centered icon, no text stripe)
    launch_image = ROOT / "apps/mobile/android/app/src/main/res/drawable/launch_image.png"
    save_fit(src, CROPS["web_favicon"], launch_image, (512, 512))


def apply_web_branding(src: Image.Image) -> None:
    web_targets = [
        ("apps/mobile/web/favicon.png", CROPS["web_favicon"], (64, 64)),
        ("apps/mobile/web/icons/Icon-192.png", CROPS["app_icon_master"], (192, 192)),
        ("apps/mobile/web/icons/Icon-512.png", CROPS["app_icon_master"], (512, 512)),
        ("apps/mobile/web/icons/Icon-maskable-192.png", CROPS["app_icon_master"], (192, 192)),
        ("apps/mobile/web/icons/Icon-maskable-512.png", CROPS["app_icon_master"], (512, 512)),
    ]
    for rel, crop, size in web_targets:
        out = ROOT / rel
        save_fit(src, crop, out, size)


def apply_distribution_assets(src: Image.Image) -> None:
    dist_targets = [
        ("distribution/assets/checklist/store_icon_512.png", CROPS["store_icon_google"], (512, 512)),
        (
            "distribution/assets/checklist/feature_graphic_1024x500.png",
            CROPS["feature_graphic"],
            (1024, 500),
        ),
        (
            "distribution/assets/checklist/screenshot_phone_01.png",
            CROPS["screenshot_01"],
            (1080, 1920),
        ),
        (
            "distribution/assets/checklist/screenshot_phone_02.png",
            CROPS["screenshot_02"],
            (1080, 1920),
        ),
        (
            "distribution/assets/checklist/screenshot_phone_03.png",
            CROPS["screenshot_03"],
            (1080, 1920),
        ),
    ]
    for rel, crop, size in dist_targets:
        out = ROOT / rel
        save_fit(src, crop, out, size)


def main() -> None:
    if not SOURCE_IMAGE.exists():
        raise FileNotFoundError(
            f"Source sheet not found: {SOURCE_IMAGE}. Put the file in repo root and rerun."
        )

    src = Image.open(SOURCE_IMAGE).convert("RGBA")
    if src.size != (2816, 1536):
        print(f"Warning: expected 2816x1536 sheet, got {src.size}. Crop quality may degrade.")

    generate_brand_pack(src)
    apply_android_branding(src)
    apply_web_branding(src)
    apply_distribution_assets(src)
    print("Brand asset generation and replacement completed.")


if __name__ == "__main__":
    main()
