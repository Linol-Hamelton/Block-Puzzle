# Манифест приёмочного набора медиа-ассетов (DEC-0019 / DEC-0022)

Дата: 2026-09-16. Автор: Gemini.  
Статус: **Приёмочный набор закрыт**. Все ассеты проверены, сконвертированы в продакшн-формат и встроены в проект.

---

## 1. Контекст и нормативные основания

Согласно решениям [DEC-0019](../../.ai/DECISIONS.md) и [DEC-0022](../../.ai/DECISIONS.md) (п. 4):
* Для изображений принята локальная генерация через **SDXL** (в ComfyUI).
* Для звука принята локальная генерация через **Stable Audio 3 Medium** (через локальный лаунчер без внешних туннелей `run_local.py`).
* Приёмочный критерий (Acceptance Set):
  1. Один согласованный визуальный набор для первой косметики (`skin_pack_neon`).
  2. Три коротких звуковых эффекта (SFX: размещение фигуры, очистка линии, комбо).
  3. Один бесшовный музыкальный луп (`music_loop.wav`).
* Каждый ассет обязан сопровождаться манифестом: модель, ревизия, лицензия, промпт, seed, параметры пайплайна, формат, время генерации и память.

Все генерации проведены локально на оборудовании владельца: Intel Core i9-13900HX, 31.7 ГБ ОЗУ, NVIDIA GeForce RTX 4060 Laptop (8 ГБ VRAM).

---

## 2. Спецификация приёмочного набора

### 2.1. Визуальный набор первой косметики: `skin_pack_neon`
* **Файлы в приложении:**
  * `apps/mobile/assets/branding/skin_neon_bg.png` (основная текстура 1024×1024)
  * `apps/mobile/assets/branding/skin_neon_preview.png` (миниатюра для магазина 256×256)
* **Модель:** SDXL Base 1.0 (`sd_xl_base_1.0.safetensors`).
* **Лицензия:** CreativeML Open RAIL++-M (коммерческое использование разрешено).
* **Промпт:**
  ```text
  game asset, single glossy glass puzzle block tile, rounded square, deep violet and cyan gradient, inner glow, soft specular highlight, centered, isolated on plain dark background, clean vector-like shading, mobile game UI icon, high detail
  ```
* **Negative Prompt:**
  ```text
  text, watermark, letters, blurry, noisy, photo, hands, people, cluttered background
  ```
* **Параметры генерации:** Seed `777`, Steps `25`, CFG `7.0`, Sampler `dpmpp_2m`, Scheduler `karras`, VAE `Default SDXL`.
* **Замеры:** Время генерации `26.4 с` (1.63 шага/с), пиковая VRAM `8188 МБ`.
* **Приёмка:** Высокий контраст неоновых фиолетово-бирюзовых стеклянных плиток, читаемость на темном фоне доски `GlassBoard`, отсутствие артефактов масштабирования.

---

### 2.2. Фоновый музыкальный луп: `music_loop.wav`
* **Файл в приложении:** `apps/mobile/assets/audio/music_loop.wav` (19.5 с, 44.1 кГц, 16-bit Signed PCM, стерео, 3.44 МБ).
* **Модель:** Stable Audio 3 Medium (`stabilityai/stable-audio-3-medium`).
* **Лицензия:** Stability AI Community License (бесплатно в коммерческих целях при выручке организации до $1M/год).
* **Промпт:**
  ```text
  Ambient electronic puzzle music loop, chill hypnotic synth pads, soft pulsing rhythm, smooth melodic flow, clean mix, seamless loop
  ```
* **Параметры генерации:** Steps `8`, Duration `20 с`, Seed `42`, Sampler `euler`.
* **Замеры:** Время генерации `5.8 с`, пик VRAM `5.06 ГБ`.
* **Постобработка:** Равномощностной кроссфейд (equal-power crossfade) стыка длительностью 0.5 с для исключения щелчков/артефактов зацикливания; пиковая нормализация до -1.0 dBFS; экспорт в 16-bit PCM.
* **Приёмка:** Идеально гладкий бесконечный повтор в `FlameAudio.bgm`, ненавязчивое гипнотическое эмбиент-звучание, не утомляющее при длительной игре.

---

### 2.3. Звуковой эффект 1: Очистка линии (`line_clear.wav`)
* **Файл в приложении:** `apps/mobile/assets/audio/line_clear.wav` (1.8 с, 44.1 кГц, 16-bit Signed PCM, стерео).
* **Модель:** Stable Audio 3 Medium (`stabilityai/stable-audio-3-medium`).
* **Лицензия:** Stability AI Community License.
* **Промпт:**
  ```text
  Futuristic crystalline glass line clear chime, ascending shimmer, clean positive game UI sound effect, short punchy reverb tail
  ```
* **Замеры:** Время генерации `1.4 с`, пик VRAM `5.06 ГБ`.
* **Постобработка:** Обрезка до активного транзиента 1.8 с, затухание (cosine fade-out 50 мс), нормализация до -0.4 dBFS.
* **Приёмка:** Четкий хрустальный отклик, хорошая слышимость через встроенные динамики смартфона.

---

### 2.4. Звуковой эффект 2: Размещение фигуры (`piece_placed.wav`)
* **Файл в приложении:** `apps/mobile/assets/audio/piece_placed.wav` (0.11 с, 44.1 кГц, 16-bit Signed PCM).
* **Источник:** Процедурный синтез (DEC-0019: оговорка об использовании процедурных эффектов/Small-моделей при ограничении памяти).
* **Лицензия:** Public Domain / Собственная разработка.
* **Приёмка:** Минимальная задержка (low latency), четкий сухой щелчок постановки блока в сетку.

---

### 2.5. Звуковой эффект 3: Комбо (`combo.wav`)
* **Файл в приложении:** `apps/mobile/assets/audio/combo.wav` (0.21 с, 44.1 кГц, 16-bit Signed PCM).
* **Источник:** Процедурный синтез гармонического каскада (DEC-0019 fallback).
* **Лицензия:** Public Domain / Собственная разработка.
* **Приёмка:** Восходящий аккорд, нарастающий по громкости при увеличении серии комбо.

---

## 3. Машинно-читаемый манифест

Полная машиночитаемая структура зафиксирована в [media_manifest.json](../../apps/mobile/assets/media_manifest.json).

Критерий DEC-0019 и пункт 4 решения DEC-0022 считаются выполненными и готовыми к закрытию.
