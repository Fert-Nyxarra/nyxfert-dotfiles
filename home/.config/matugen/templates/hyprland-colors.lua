-- ~/.config/matugen/templates/hyprland-colors.lua
-- генерирует matugen -> ~/.config/hypr/colors.lua
return {
  -- активное окно: один цвет, без градиента
  active_border = "rgba({{colors.primary.dark.hex_stripped}}ff)",

  -- неактивное окно: приглушённая полупрозрачная рамка
  inactive_border = "rgba({{colors.outline_variant.dark.hex_stripped}}aa)",
}
