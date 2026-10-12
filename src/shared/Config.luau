--!strict
--[[
	Config

	Fuente única de verdad para todos los números de balance del juego:
	precios, tiempos, recompensas, límites, probabilidades.

	Regla: ningún sistema escribe un número de balance inline. Si un valor
	afecta cómo se siente o cómo se equilibra el juego, vive aquí. Así se
	puede ajustar el balance sin tocar lógica y se revisa en un solo lugar.

	Este módulo vive en ReplicatedStorage para que el cliente pueda MOSTRAR
	valores (por ejemplo, un precio en la UI). El servidor sigue siendo el
	único que DECIDE: el cliente nunca usa Config para validar nada.

	Cómo agregar valores:
		1. Declarar el campo en el tipo de la sección correspondiente.
		2. Asignar el valor en la tabla Config.
		3. Documentar la unidad (segundos, studs, monedas) en un comentario.
]]

-- Economía: monedas, precios, recompensas.
export type EconomyConfig = {}

-- Progresión: niveles, experiencia, desbloqueos.
export type ProgressionConfig = {}

-- Jugabilidad: tiempos, velocidades, rangos, cooldowns.
export type GameplayConfig = {}

export type Config = {
	Economy: EconomyConfig,
	Progression: ProgressionConfig,
	Gameplay: GameplayConfig,
}

local Config: Config = {
	Economy = {},
	Progression = {},
	Gameplay = {},
}

-- Congelado para que ningún sistema pueda modificar el balance en tiempo de ejecución.
return table.freeze(Config)
