# GamepadControl

Конфигурационный репозиторий для управления macOS с Xbox-контроллера. Хранит профили, скрипты настройки и утилиты. Основной демон — [gamacros](./gamacros/) (Rust, подключён как вложенный репо).

## Структура

```
config/
  gc_profile.yaml    — профиль gamacros (симлинк → ~/Library/Application Support/gamacros/)
  aerospace.toml     — конфиг AeroSpace (симлинк → ~/.config/aerospace/)
gamacros/            — демон gamacros (Rust workspace, отдельный репо github.com/IlyaGulya/gamacros)
tools/
  keymon.swift       — утилита для отладки клавиатурных событий
docs/
  layout.svg         — схема раскладки
setup.sh             — установка зависимостей, симлинки, запуск сервисов
```

## Быстрый старт

```bash
./setup.sh           # установит AeroSpace, SDL2, Rust, gamacros; создаст симлинки
```

## Сборка gamacros

```bash
cd gamacros
just install         # cargo install --release + codesign
just build           # release build без install
just qa              # lint + format check + tests
```

Codesign identity: "FreeFlow Debug". Бинарник: `~/.cargo/bin/gamacrosd`.

Демон авто-рестартится через launchd (kill → перезапуск). Профиль перечитывается автоматически — перезапуск демона для изменения конфига не нужен.

## Профиль gc_profile.yaml

### Основные понятия

- **Groups** — именованные наборы bundle ID приложений (`browser`, `messaging`, `wezterm`, `cmux`)
- **Rules** — маппинги кнопок/стиков. `common` для всех; `$groupname` переопределяет per-app
- **Слои**: без модификатора = базовый, `lt+кнопка` = навигация, `rt+кнопка` = управление окнами
- App-specific правила **переопределяют** common для той же кнопки (не мержатся)

### Доступные действия

| Действие     | YAML-ключ    | Поведение                                     |
|--------------|--------------|-----------------------------------------------|
| keystroke    | `keystroke`  | Нажать+отпустить, повторяет при удержании      |
| tap          | `tap`        | Одиночное нажатие+отпускание, без повтора      |
| hold         | `hold`       | Нажать при down, отпустить при up (модификаторы)|
| macros       | `macros`     | Последовательность комбо: `[cmd+a, backspace]` |
| shell        | `shell`      | Выполнить shell-команду (async spawn)           |
| click        | `click`      | Клик мыши: left/right/middle/double             |
| hold_click   | `hold_click` | Зажатие кнопки мыши (для drag)                  |
| rawkey       | `rawkey`     | Raw macOS FlagsChanged (для голосовых приложений)|

Доп. свойства: `vibrate`, `repeat_delay_ms`, `repeat_interval_ms`.

### Кнопки

Face: `a`, `b`, `x`, `y`. Бамперы: `lb`/`rb`. Триггеры: `lt`/`rt`. D-pad: `dpad_up/down/left/right`. Другие: `start`, `back`, `left_stick`/`ls`, `right_stick`/`rs`, `guide`/`home`. Аккорды: `lt+a`, `rt+dpad_left` и т.д.

### Режимы стиков

- `mouse_move` — управление курсором (deadzone, max_speed_px_s, gamma, precision_button, precision_multiplier, tick_ms, smoothing_window_ms)
- `scroll` — прокрутка (deadzone, speed_lines_s, gamma, tick_ms, smoothing_window_ms, trigger_boost_max, trigger_boost_gamma)
- `arrows` — эмуляция D-pad
- `volume` / `brightness` — системные регулировки

### Важно: LT = precision_button

LT настроен как `precision_button` для mouse_move. При нажатии LT скорость курсора снижается до 0.25x. Любой аккорд `lt+кнопка` также активирует precision mode.

## Интеграции

### AeroSpace

Тайловый оконный менеджер. Используется через `shell: aerospace <command>` на RT-слое для управления окнами (focus, move, fullscreen, layout).

### cmux

Нативный macOS AI-терминал (bundle: `com.cmuxterm.app`). CLI: `/Applications/cmux.app/Contents/Resources/bin/cmux`.

**Для gamepad-биндингов использовать клавиатурные шорткаты, а не CLI** — shell-команды cmux из gamacrosd работают ненадёжно.

Иерархия cmux: Window > Workspace (вертикальные табы слева) > Pane (сплиты) > Surface (табы внутри сплита).

#### Шорткаты cmux

| Действие             | Шорткат               |
|----------------------|------------------------|
| Previous Workspace   | `ctrl+cmd+[`           |
| Next Workspace       | `ctrl+cmd+]`           |
| Previous Surface     | `cmd+shift+[`          |
| Next Surface         | `cmd+shift+]`          |
| New Workspace        | `cmd+n`                |
| Close Workspace      | `cmd+shift+w`          |
| New Surface          | `cmd+t`                |
| Split Right          | `cmd+d`                |
| Split Down           | `cmd+shift+d`          |
| Focus Pane Left      | `option+cmd+arrow_left`  |
| Focus Pane Right     | `option+cmd+arrow_right` |
| Focus Pane Up        | `option+cmd+arrow_up`    |
| Focus Pane Down      | `option+cmd+arrow_down`  |
| Toggle Sidebar       | `cmd+b`                |
| Jump to Unread       | `cmd+shift+u`          |
| Workspace 1-8        | `cmd+1` ... `cmd+8`    |

### WezTerm

Терминал (bundle: `com.github.wez.wezterm`). setup.sh патчит `~/.wezterm.lua` для поддержки `cmd+shift+[/]` переключения табов.
