--!strict
--[[
	Config.Habitats

	La zona decorada de cada monstruo dentro del cráter (la arma
	server/World/HabitatService con los modelos de ServerStorage.Habitats.<GiantId>).
	Por GiantId, la lista de props; un mismo prop puede repetirse.

		prop    nombre del Model en ServerStorage.Habitats.<GiantId>
		angulo  grados desde +X del cráter (x = cos, z = sin)
		radio   studs desde el centro del cráter. 158-178: repisa bajo el agua;
		        194-197: ladera del acantilado, junto al camino (props altos y finos)
		escala  para Model:ScaleTo (los modelos vienen a escala 1)
		giro    grados extra sobre "el frente mira hacia afuera, a los jugadores del borde"

	La distribución inicial es el atributo Sugerido que dejó Cowork en cada carpeta.
	Zonas libres (HabitatService descarta lo que caiga ahí): el centro, para el
	gigante (giantClearRadius, que también cubre la guarida del descanso), y desde el
	acantilado hacia afuera (WorldLayout.craterCliffRadius: el camino de los jugadores).
]]

export type HabitatProp = {
	prop: string,
	angulo: number,
	radio: number,
	escala: number,
	giro: number,
}

export type HabitatsConfig = {
	giantClearRadius: number,
	slopeRadius: number,
	sinkStuds: number,
	probeFraction: number,
	rayTopHeight: number,
	rayLength: number,
	light: {
		brightness: number,
		range: number,
		maxRange: number,
		fireColor: Color3,
	},
	fire: {
		size: number,
		heat: number,
		color: Color3,
		secondaryColor: Color3,
	},
	glow: {
		seconds: number,
		transparency: number,
	},
	byGiant: { [string]: { HabitatProp } },
}

local Habitats: HabitatsConfig = {
	giantClearRadius = 95, -- E4 mide ~165 de alto y ~80 de ancho: nada más cerca del centro
	slopeRadius = 185, -- desde aquí es ladera: se apoya en la altura más baja (si no, flota)
	sinkStuds = 0.5, -- la base se hunde un poco en el terreno
	probeFraction = 0.3, -- 4 rayos más, a 0.3 del ancho y del fondo del prop
	rayTopHeight = 80, -- los rayos bajan desde esta altura...
	rayLength = 320, -- ...y hasta esta distancia
	light = {
		brightness = 2,
		range = 14, -- a escala 1; crece con la escala del prop
		maxRange = 40,
		fireColor = Color3.fromRGB(255, 150, 50), -- "fuego" sin ColorLuz
	},
	fire = { -- solo en el cliente y sin modo rápido
		size = 4, -- a escala 1
		heat = 9,
		color = Color3.fromRGB(255, 140, 40),
		secondaryColor = Color3.fromRGB(255, 60, 20),
	},
	glow = { -- "brillo": el Neon late suave
		seconds = 2.6, -- una vuelta del latido
		transparency = 0.45, -- la más transparente que llega
	},
	byGiant = {
		Minotauro = {
			{ prop = "Arco", angulo = 90, radio = 168, escala = 2.2, giro = 0 },
			{ prop = "Muro", angulo = 30, radio = 165, escala = 1.8, giro = 10 },
			{ prop = "Muro", angulo = 150, radio = 165, escala = 1.8, giro = -10 },
			{ prop = "Muro", angulo = 250, radio = 162, escala = 1.7, giro = -20 },
			{ prop = "ColumnaRota", angulo = 300, radio = 168, escala = 2, giro = 40 },
			{ prop = "ColumnaRota", angulo = 340, radio = 160, escala = 1.8, giro = -20 },
			{ prop = "ColumnaRota", angulo = 200, radio = 165, escala = 1.8, giro = 0 },
			{ prop = "CraneoToro", angulo = 270, radio = 160, escala = 2.4, giro = 20 },
			{ prop = "Brasero", angulo = 80, radio = 180, escala = 2.4, giro = 0 },
			{ prop = "Brasero", angulo = 100, radio = 180, escala = 2.4, giro = 0 },
			{ prop = "Columna", angulo = 65, radio = 196, escala = 1.8, giro = 0 },
			{ prop = "Columna", angulo = 115, radio = 196, escala = 1.8, giro = 0 },
			{ prop = "Columna", angulo = 200, radio = 196, escala = 1.9, giro = 0 },
			{ prop = "Columna", angulo = 320, radio = 196, escala = 1.8, giro = 0 },
			{ prop = "Estandarte", angulo = 10, radio = 197, escala = 2, giro = 0 },
			{ prop = "Estandarte", angulo = 180, radio = 197, escala = 2, giro = 0 },
			{ prop = "Estandarte", angulo = 230, radio = 197, escala = 1.8, giro = 0 },
			{ prop = "Brasero", angulo = 225, radio = 196, escala = 2.2, giro = 0 },
			{ prop = "Brasero", angulo = 315, radio = 196, escala = 2.2, giro = 0 },
		},
		Orca = {
			{ prop = "Almeja", angulo = 90, radio = 162, escala = 2.6, giro = 0 },
			{ prop = "RocaPercebes", angulo = 30, radio = 168, escala = 2.2, giro = 0 },
			{ prop = "RocaPercebes", angulo = 215, radio = 165, escala = 2.4, giro = -60 },
			{ prop = "CoralRama", angulo = 60, radio = 165, escala = 2.2, giro = 0 },
			{ prop = "CoralRama", angulo = 170, radio = 170, escala = 2, giro = -90 },
			{ prop = "CoralRama", angulo = 300, radio = 160, escala = 2.4, giro = 20 },
			{ prop = "CoralRamaNaranja", angulo = 120, radio = 160, escala = 2.2, giro = 40 },
			{ prop = "CoralRamaNaranja", angulo = 250, radio = 172, escala = 2.2, giro = 10 },
			{ prop = "CoralRamaNaranja", angulo = 5, radio = 160, escala = 2, giro = 0 },
			{ prop = "CoralCerebro", angulo = 140, radio = 166, escala = 2.2, giro = 0 },
			{ prop = "CoralCerebro", angulo = 330, radio = 170, escala = 2, giro = 0 },
			{ prop = "CoralCerebro", angulo = 200, radio = 175, escala = 1.8, giro = 0 },
			{ prop = "CoralAbanico", angulo = 10, radio = 178, escala = 2.2, giro = 0 },
			{ prop = "CoralAbanico", angulo = 195, radio = 178, escala = 2, giro = 0 },
			{ prop = "CoralAbanico", angulo = 270, radio = 175, escala = 2, giro = 0 },
			{ prop = "Alga", angulo = 45, radio = 194, escala = 2, giro = 0 },
			{ prop = "Alga", angulo = 160, radio = 194, escala = 1.8, giro = 70 },
			{ prop = "Alga", angulo = 275, radio = 194, escala = 2, giro = -40 },
			{ prop = "Alga", angulo = 100, radio = 194, escala = 1.8, giro = 0 },
			{ prop = "Alga", angulo = 340, radio = 194, escala = 1.9, giro = 0 },
		},
		DragonMarino = {
			{ prop = "Nido", angulo = 90, radio = 164, escala = 2.4, giro = 0 },
			{ prop = "Costillar", angulo = 240, radio = 168, escala = 1.8, giro = 95 },
			{ prop = "Obsidiana", angulo = 30, radio = 170, escala = 2, giro = 0 },
			{ prop = "Obsidiana", angulo = 150, radio = 172, escala = 1.8, giro = 70 },
			{ prop = "Obsidiana", angulo = 310, radio = 168, escala = 2.2, giro = -40 },
			{ prop = "Fumarola", angulo = 0, radio = 160, escala = 2.2, giro = 0 },
			{ prop = "Fumarola", angulo = 180, radio = 158, escala = 2, giro = 0 },
			{ prop = "Fumarola", angulo = 275, radio = 172, escala = 1.8, giro = 0 },
			{ prop = "CristalLava", angulo = 60, radio = 196, escala = 2.2, giro = 0 },
			{ prop = "CristalLava", angulo = 120, radio = 196, escala = 2, giro = 0 },
			{ prop = "CristalLava", angulo = 200, radio = 196, escala = 2.2, giro = 0 },
			{ prop = "CristalLava", angulo = 345, radio = 196, escala = 2, giro = 0 },
			{ prop = "CristalLava", angulo = 280, radio = 196, escala = 1.8, giro = 0 },
		},
		OrcaFantasma = {
			{ prop = "BarcoHundido", angulo = 205, radio = 168, escala = 1.8, giro = 75 },
			{ prop = "Calabaza", angulo = 20, radio = 168, escala = 2.4, giro = 0 },
			{ prop = "Calabaza", angulo = 120, radio = 170, escala = 1.8, giro = 20 },
			{ prop = "Calabaza", angulo = 300, radio = 165, escala = 2, giro = -20 },
			{ prop = "Calabaza", angulo = 245, radio = 175, escala = 1.5, giro = 0 },
			{ prop = "Lapida", angulo = 95, radio = 160, escala = 2.4, giro = -5 },
			{ prop = "LapidaCruz", angulo = 103, radio = 168, escala = 2.2, giro = 10 },
			{ prop = "Lapida", angulo = 110, radio = 158, escala = 2, giro = 15 },
			{ prop = "Lapida", angulo = 280, radio = 162, escala = 2.2, giro = -10 },
			{ prop = "LapidaCruz", angulo = 140, radio = 160, escala = 2.4, giro = 5 },
			{ prop = "LapidaCruz", angulo = 330, radio = 165, escala = 2, giro = 0 },
			{ prop = "Ataud", angulo = 345, radio = 160, escala = 2.2, giro = 30 },
			{ prop = "Ataud", angulo = 175, radio = 165, escala = 2, giro = -40 },
			{ prop = "ArbolSeco", angulo = 70, radio = 196, escala = 2.2, giro = 0 },
			{ prop = "ArbolSeco", angulo = 255, radio = 196, escala = 2, giro = -90 },
			{ prop = "ArbolSeco", angulo = 150, radio = 196, escala = 1.8, giro = 40 },
			{ prop = "FarolFantasma", angulo = 45, radio = 197, escala = 2.2, giro = 0 },
			{ prop = "FarolFantasma", angulo = 165, radio = 197, escala = 2.2, giro = 0 },
			{ prop = "FarolFantasma", angulo = 330, radio = 197, escala = 2.2, giro = 0 },
			{ prop = "FarolFantasma", angulo = 280, radio = 197, escala = 2.2, giro = 0 },
		},
	},
}

return Habitats
