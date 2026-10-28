# P2-3: Static GUI Migration Guide
## Удаление GUI Creation Scripts и переход на статический StarterGui

---

## 📋 ОБЗОР

Эта задача требует ручной работы в Roblox Studio для миграции динамически создаваемых GUI в статические объекты в StarterGui.

**Преимущества:**
- Быстрее загрузка (GUI уже созданы)
- Легче редактировать в Studio
- Меньше кода для поддержки

---

## 🎯 ШАГИ ВЫПОЛНЕНИЯ

### Шаг 1: Подготовка

1. Откройте проект в Roblox Studio
2. Убедитесь, что все GUI creation scripts работают корректно
3. Запустите игру в Studio (Play Solo)

### Шаг 2: Создание GUI через скрипты

1. Дождитесь полной загрузки игры
2. Проверьте, что все GUI созданы и отображаются:
   - HUD (CurrencyDisplay, DayNightIndicator, Hotbar)
   - InventoryUI (InventoryFrame с табами и grid)
   - ShopUI (ShopFrame с категориями и панелями)

### Шаг 3: Копирование GUI в StarterGui

1. **Остановите игру** (Stop)
2. В Explorer найдите `Players > LocalPlayer > PlayerGui`
3. Найдите созданные ScreenGui:
   - `HUD`
   - `InventoryUI`
   - `ShopUI`

4. **Скопируйте каждый ScreenGui:**
   - Правый клик на `HUD` → Copy
   - Перейдите в `StarterGui`
   - Правый клик → Paste
   - Повторите для `InventoryUI` и `ShopUI`

### Шаг 4: Проверка структуры

Убедитесь, что в StarterGui теперь есть:
```
StarterGui/
├── HUD (ScreenGui)
│   ├── CurrencyDisplay
│   ├── DayNightIndicator
│   └── Hotbar
├── InventoryUI (ScreenGui)
│   └── InventoryFrame
└── ShopUI (ScreenGui)
    └── ShopFrame
```

### Шаг 5: Удаление creation scripts

После успешного копирования можно удалить:
- `StarterGui/CreateHUD.lua`
- `StarterPlayer/StarterPlayerScripts/CreateInventoryUI.lua`
- `StarterGui/CreateShopUI.lua`

**⚠️ ВАЖНО:** Удаляйте только после проверки, что статический GUI работает!

### Шаг 6: Проверка работы контроллеров

1. Запустите игру снова
2. Проверьте, что контроллеры находят GUI:
   - UIController должен найти HUD
   - InventoryController должен найти InventoryUI
   - ShopController должен найти ShopUI

3. Проверьте функциональность:
   - Открытие/закрытие инвентаря (клавиша I)
   - Открытие/закрытие магазина (клавиша B)
   - Обновление валюты
   - Работа hotbar

---

## ✅ КРИТЕРИИ ПРИЕМКИ

- [x] Все GUI скопированы в StarterGui
- [x] GUI отображаются при запуске игры
- [x] Контроллеры находят GUI элементы
- [x] Все функции работают (открытие, закрытие, обновления)
- [x] Creation scripts удалены (исходники — в `Tools/StaticGui/builders/`)

---

## 🔄 ОТКАТ ИЗМЕНЕНИЙ

Если что-то пошло не так:

1. Удалите GUI из StarterGui
2. Восстановите creation scripts (если удалили)
3. Перезапустите игру

---

## 📝 ЗАМЕТКИ

- Статический GUI будет автоматически копироваться в PlayerGui при присоединении игрока
- Если нужно изменить GUI, редактируйте в StarterGui, а не в коде
- Creation scripts можно оставить как backup на случай необходимости изменений

---

**Статус:** ✅ Выполнено 28.10.2026 (ветка `studio-sync-2026-10-28`)

---

## 🛠 КАК ВЫПОЛНЕНО

Вместо ручного копирования из PlayerGui:

1. Код Create*UI прогнан через `Tools/StaticGui/GuiRecorder.luau` прямо в Studio
   с целью StarterGui (без обработчиков событий) — получились HUD (40 объектов),
   InventoryUI (27) и ShopUI (39).
2. Тот же код локально прогнан через Luau с имитацией Roblox API —
   получились `StarterGui/*.model.json` для Rojo. Отпечатки обоих деревьев
   совпали (в Studio значения прочитаны обратно из настоящих объектов).
3. Логика, которая была в Create*UI помимо построения, перенесена в контроллеры
   через `Utils/GuiEffects.lua`: hover-цвета (Close, −, +, BUY), подсветка
   вкладок инвентаря (`InventoryController.SwitchTab`), вращение спиннера.
4. Create*UI удалены из StarterGui; исходники остались в
   `Tools/StaticGui/builders/` как источник для повторной генерации.

Попутно исправлено:
- контроллеры ждали ScreenGui максимум 10 с — при медленном появлении
  персонажа GUI оставался без ссылок; теперь ожидание без таймаута;
- `TooltipFrame` искался внутри `InventoryFrame`, хотя лежит в `InventoryUI` —
  подсказки не показывались и старт задерживался на 5 с;
- клавиша `I` занята зумом камеры Roblox (gameProcessed = true) — инвентарь
  по I не открывался никогда; теперь привязка через ContextActionService
  с приоритетом выше камеры;
- символ `✕` в шрифте Gotham отсутствует (рисовался пустым прямоугольником) —
  заменён на `X`.

Известное ограничение: `Escape` зарезервирована системным меню Roblox,
закрытие окон по Esc не срабатывает (было так и раньше).

