--!strict
--[[
	UIConfig

	Constantes visuales de la interfaz: paleta de colores, fuentes, tamaños
	de texto, espaciados y curvas de animación (TweenInfo).

	Separado de Config.luau a propósito: Config contiene balance de juego
	(lo que afecta las reglas) y UIConfig contiene presentación (lo que
	afecta cómo se ve). Cambiar un color nunca debería requerir revisar
	la economía, y viceversa.

	Los IDs de imágenes NO van aquí; van en Assets.luau.
]]

export type UIConfig = {
	-- Paleta con nombre semántico (Primary, Background, Danger), no por color (Red).
	Colors: { [string]: Color3 },

	-- Familias tipográficas de Enum.Font o Font.new(...).
	Fonts: { [string]: Font },

	-- Tamaños de texto en píxeles.
	TextSizes: { [string]: number },

	-- Márgenes y separaciones en píxeles, para mantener un ritmo consistente.
	Spacing: { [string]: number },

	-- Curvas reutilizables para TweenService (abrir paneles, flotar, girar).
	Tweens: { [string]: TweenInfo },
}

local UIConfig: UIConfig = {
	Colors = {},

	Fonts = {},

	TextSizes = {},

	Spacing = {},

	Tweens = {},
}

return table.freeze(UIConfig)
