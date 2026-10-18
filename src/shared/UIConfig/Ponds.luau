--!strict
--[[
	Estanques de entrenamiento (sección de UIConfig en su propio archivo): color y
	nombre de cada uno, del más débil al más fuerte; el 11 es el sagrado del centro.
	El color es el mismo de sus piezas (COLORES_ESTANQUE en tools/generar_isla.py) y
	el nombre, el de una piedra de ese color (tools/estanques/temas). Los muestra el
	cartel (PondSigns).
]]

local Ponds = {
	Colors = {
		Color3.fromRGB(120, 220, 120),
		Color3.fromRGB(90, 210, 200),
		Color3.fromRGB(90, 170, 255),
		Color3.fromRGB(130, 120, 255),
		Color3.fromRGB(190, 110, 255),
		Color3.fromRGB(255, 110, 200),
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(255, 150, 60),
		Color3.fromRGB(255, 205, 60),
		Color3.fromRGB(255, 245, 170),
		Color3.fromRGB(120, 245, 255),
	},
	Names = {
		"Estanque de Jade",
		"Estanque Turquesa",
		"Estanque de Zafiro",
		"Estanque Índigo",
		"Estanque de Amatista",
		"Estanque Rosa",
		"Estanque de Rubí",
		"Estanque de Ámbar",
		"Estanque Dorado",
		"Estanque Celestial",
		"Estanque Sagrado",
	},
}

return Ponds
