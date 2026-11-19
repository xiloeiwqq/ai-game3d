# Архитектура

## Поток данных

```text
Описание пользователя
  ├─ AI mode ──> LLMWorldService ──> JSON
  └─ Offline ──> ProceduralGenerator ──> Dictionary
                                      │
                                      v
                              WorldValidator
                         schema + whitelist + BFS
                                      │
                                      v
                                 SaveService
                                      │
                                      v
                                 WorldBuilder
               floor + environment + objects + items + exit + player
```

## Границы модулей

- `scripts/core/main.gd` управляет экранами и жизненным циклом мира, но не генерирует JSON и не строит меши.
- `scripts/ai/llm_world_service.gd` отвечает только за сетевой протокол, prompt, извлечение JSON и повторы.
- `scripts/generation/procedural_generator.gd` — честная локальная альтернатива LLM.
- `scripts/validation/world_validator.gd` не доверяет ни LLM, ни файлам и проверяет данные перед сборкой.
- `scripts/navigation/grid_pathfinder.gd` выполняет BFS независимо от UI и Godot-сцен.
- `scripts/generation/world_builder.gd` принимает только уже проверенный словарь мира.
- `scripts/generation/visual_factory.gd` создаёт реальные процедурные меши и материалы для ID из каталога.
- `scripts/core/resource_catalog.gd` — единственный источник разрешённых ресурсов и footprint.
- `scripts/core/app_state.gd` хранит состояние одного прохождения и рассылает сигналы HUD/порталу.

## Модель безопасности

LLM не управляет сценой напрямую. Он может вернуть только данные JSON 1.0. Каждый `resource_id`:

1. не должен содержать `/`, `\\` или `..`;
2. должен существовать в `data/catalog/resources.json`;
3. должен принадлежать ожидаемой категории (`object`, `collectible`, `exit`).

Координаты целочисленные, повороты ограничены `0/90/180/270`, карта — `12..40`, число объектов — не более 140. Footprint после поворота участвует и в пересечениях, и в blocked-grid BFS.

## Воспроизводимость

Офлайн seed вычисляется из текста описания и `seed_offset`. Один текст и параметры дают идентичный JSON. Сохранение записывает:

- полный мир;
- исходное описание;
- режим генерации;
- версию каталога;
- время сохранения.

Служебный `_save_meta` удаляется перед повторной валидацией/запуском.

## 3D-каталог

Каталог не содержит отсутствующих GLB. Визуальные модели строятся из `BoxMesh`, `CylinderMesh`, `SphereMesh` и `TorusMesh`, объединённых в стилизованные деревья, стены, башни, роботов, контейнеры, кристаллы и порталы. Физический размер каждого блокирующего объекта берётся из того же каталога, что и footprint валидатора.
