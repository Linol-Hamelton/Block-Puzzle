# UI/UX и Art Direction (Hypnotic Gameplay)

## 1. Дизайн-цель
Создать визуально "чистую", премиальную и эмоционально насыщенную игру, где:
- интерфейс не отвлекает от поля;
- каждый успешный ход вызывает микро-удовлетворение;
- прогресс и награды читаются мгновенно.

## 2. Принципы UX
1. One-screen focus: во время раунда только важные элементы.
2. Zero-friction loop: максимум 1-2 действия до следующего раунда.
3. Predictable controls: drag behavior без сюрпризов.
4. Layered feedback: визуал + звук + haptic.
5. Respectful monetization UX: реклама не должна ломать flow.

## 3. Визуальное направление
- Стиль: минималистичный premium casual, высокая читаемость.
- Палитра:
  - базовые нейтральные тона для поля;
  - акцентные цвета для комбинаций и high-value действий;
  - отдельная семантика цветов для валидной/невалидной постановки.
- Формы:
  - мягкие скругления;
  - контрастные тени/подсветки для depth;
  - четкая иерархия размера элементов.

## 4. Motion/Animation принципы
- Input response: <= 120 ms на drag/placement feedback.
- Line clear: каскад с нарастающим импактом при multi-line clear.
- Combo: на каждом шаге возрастает интенсивность VFX/SFX.
- Game Over: короткая драматургия + быстрый переход к replay.

## 5. Audio/Feel
- Минимум 3 слоя звука:
  - базовый placement;
  - clear impact;
  - combo escalation.
- Аудио должно усиливать ритм, но не утомлять при длинной сессии.

## 6. Design System (v1)
- Typography: 1 display + 1 UI font, строгая шкала размеров.
- Components:
  - Buttons (primary/secondary/ghost)
  - HUD counters
  - Modal templates (game over, reward)
  - Shop cards
- Tokens:
  - color tokens
  - spacing scale
  - animation durations

## 7. UX-метрики качества
- Tutorial completion rate.
- Time-to-first-move.
- Restart latency после game over.
- Rage-quit rate в первые 3 сессии.
- Повторные сессии в первые 24 часа.

## 8. Арт-пайплайн
- Этап 1: graybox + style probes.
- Этап 2: beta visual kit (основные ассеты поля и блоков).
- Этап 3: polish pass (VFX, transitions, micro-animations).
- Этап 4: seasonal skin pipeline для LiveOps.
