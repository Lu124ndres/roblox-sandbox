--!strict
--[[
	Loading

	Tiempos, colores y textos de la pantalla de carga (ReplicatedFirst/LoadingScreen).
	Sección de UIConfig en su propio archivo y sin require: la pantalla corre antes
	de que llegue el resto de ReplicatedStorage y espera solo este módulo (se pide
	como UIConfig.Loading).

	Tiempos en segundos. La barra no avanza sola: sigue la carga real (llegada del
	juego, personaje y guardado, el mapa alrededor del personaje, imágenes y sonidos) y se
	suaviza con fillSpeed.
]]

export type LoadingLook = {
	minSeconds: number, -- dura al menos esto aunque todo cargue antes (se ve la animación)
	maxSeconds: number, -- se cierra sola pase lo que pase
	skipAfter: number, -- aparece el botón SALTAR
	fillSpeed: number, -- fracción de barra por segundo que alcanza como mucho
	joinGuessSeconds: number, -- cuánto se espera que tarde en llegar el mundo
	tipSeconds: number, -- cada cuánto cambia el consejo
	fadeSeconds: number, -- fundido de salida
	emberEvery: number, -- una chispa de lava cada tanto
	emberMax: number, -- chispas a la vez como máximo
	-- Hasta dónde llega la barra al terminar cada fase (0..1).
	phaseEnds: { join: number, player: number, world: number, assets: number },
	colors: { [string]: Color3 },
	gold: ColorSequence, -- el dorado de los títulos (igual que Interface/Kit.GOLD)
	lava: ColorSequence, -- relleno de la barra
	title: string,
	subtitle: string,
	status: { join: string, player: string, world: string, assets: string, done: string },
	tips: { string },
}

local rgb = Color3.fromRGB

local Loading: LoadingLook = {
	minSeconds = 6,
	maxSeconds = 45,
	skipAfter = 8,
	fillSpeed = 0.45,
	joinGuessSeconds = 5,
	tipSeconds = 4.5,
	fadeSeconds = 0.8,
	emberEvery = 0.12,
	emberMax = 40,

	phaseEnds = { join = 0.15, player = 0.3, world = 0.85, assets = 1 },

	colors = {
		Backdrop = rgb(26, 16, 22), -- mientras llega la imagen del fondo
		Shade = rgb(12, 6, 10), -- oscurecido de abajo para leer la barra
		Track = rgb(34, 24, 22), -- piedra volcánica del hueco de la barra
		TrackBlock = rgb(48, 34, 30),
		Frame = rgb(255, 206, 84), -- canto dorado
		FrameDark = rgb(42, 22, 8), -- contorno de los textos dorados
		Text = rgb(255, 255, 255),
		TextMuted = rgb(255, 228, 196),
		TextStroke = rgb(30, 14, 8),
		Ember = rgb(255, 150, 40),
		EmberHot = rgb(255, 228, 120),
		FishBody = rgb(255, 140, 40),
		FishBelly = rgb(255, 214, 120),
		FishFin = rgb(232, 84, 40),
		FishEye = rgb(20, 20, 24),
	},

	gold = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 246, 170)),
		ColorSequenceKeypoint.new(0.45, rgb(255, 214, 82)),
		ColorSequenceKeypoint.new(1, rgb(222, 128, 30)),
	}),
	lava = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(214, 46, 20)),
		ColorSequenceKeypoint.new(0.6, rgb(255, 128, 30)),
		ColorSequenceKeypoint.new(1, rgb(255, 214, 90)),
	}),

	title = "ALIMENTA A LOS GIGANTES",
	subtitle = "FEED THE GIANTS",
	status = {
		join = "Llegando a la isla...",
		player = "Preparando tu caña...",
		world = "Cargando la isla y el volcán...",
		assets = "Despertando a los gigantes...",
		done = "¡Listo!",
	},
	tips = {
		"Los peces raros llenan mucho más al gigante.",
		"Entrena en los estanques para pescar más rápido.",
		"Cuando el gigante se llena, todos los que ayudaron ganan una kill.",
		"Una canasta más grande te deja llevar más peces al volcán.",
		"Desde Legendario, todo el servidor ve tu pez.",
		"Si el pez se escapa no pierdes nada: vuelve a intentarlo.",
		"Mantén E en el cráter para alimentar al gigante.",
		"Cada especie nueva de la colección te paga monedas.",
		"La ruleta elige el siguiente monstruo después del descanso.",
		"Pesca con amigos: todos alimentan al mismo gigante.",
	},
}

return table.freeze(Loading)
