--!strict
--[[
	SkyMoods

	Los ambientes que mezcla SkyCycle: los momentos del día (entre dos se
	interpola), el del Cráter del Abismo (luz de lava), el del desierto del
	minotauro (sol alto y polvo: reemplaza al del cráter mientras está la
	arena), el de la guarida volcánica del dragón (más roja, mientras está la
	lava), el del lago helado del zorro (luz fría y niebla azulada, mientras
	está el hielo) y el amanecer del descanso (al llenar al monstruo sale el
	sol: luz clara y cálida).
]]

export type Mood = {
	hour: number,
	brightness: number,
	atmosphere: Color3,
	decay: Color3,
	density: number,
	tint: Color3,
	ambient: Color3,
}

local function mood(
	hour: number,
	brightness: number,
	atmosphere: Color3,
	decay: Color3,
	density: number,
	tint: Color3,
	ambient: Color3
): Mood
	return {
		hour = hour,
		brightness = brightness,
		atmosphere = atmosphere,
		decay = decay,
		density = density,
		tint = tint,
		ambient = ambient,
	}
end

local rgb = Color3.fromRGB
local NIGHT =
	mood(0, 1.2, rgb(70, 82, 130), rgb(24, 30, 60), 0.34, rgb(200, 214, 255), rgb(80, 90, 130))
local NOON = mood(
	9,
	2.2,
	rgb(200, 222, 238),
	rgb(108, 143, 174),
	0.28,
	rgb(255, 251, 245),
	rgb(116, 118, 130)
)

local SkyMoods = {}

SkyMoods.day = {
	NIGHT,
	mood(
		5.6,
		1.4,
		rgb(110, 110, 160),
		rgb(60, 50, 90),
		0.34,
		rgb(220, 214, 255),
		rgb(100, 100, 140)
	),
	mood(
		6.8,
		1.9,
		rgb(255, 196, 170),
		rgb(200, 120, 110),
		0.32,
		rgb(255, 236, 222),
		rgb(150, 130, 130)
	),
	NOON,
	mood(16.5, NOON.brightness, NOON.atmosphere, NOON.decay, NOON.density, NOON.tint, NOON.ambient),
	mood(
		18.4,
		1.8,
		rgb(255, 176, 130),
		rgb(196, 96, 92),
		0.33,
		rgb(255, 226, 205),
		rgb(160, 120, 120)
	),
	mood(
		19.6,
		1.4,
		rgb(120, 96, 150),
		rgb(60, 40, 80),
		0.34,
		rgb(214, 206, 255),
		rgb(100, 92, 130)
	),
	mood(
		24,
		NIGHT.brightness,
		NIGHT.atmosphere,
		NIGHT.decay,
		NIGHT.density,
		NIGHT.tint,
		NIGHT.ambient
	),
}

-- Cráter: claro para jugar, pero con bruma y luz de lava (peligro). Tiene su
-- propia hora (craterHour): sol de tarde aunque en la isla sea de noche, si no
-- de noche solo queda la luz ambiente y no se ve al monstruo.
SkyMoods.crater =
	mood(0, 2.1, rgb(255, 130, 80), rgb(200, 70, 40), 0.24, rgb(255, 232, 214), rgb(205, 140, 115))
SkyMoods.craterHour = 15.5
SkyMoods.craterSaturation = 0.12
SkyMoods.craterContrast = 0.12

-- Desierto (CraterMode "sand"): sol de mediodía, aire dorado con polvo en
-- suspensión, sombras más tibias y colores un poco lavados por el calor.
SkyMoods.desert =
	mood(0, 2.6, rgb(255, 212, 150), rgb(222, 156, 96), 0.3, rgb(255, 240, 212), rgb(214, 178, 136))
SkyMoods.desertHour = 13
SkyMoods.desertSaturation = 0.02
SkyMoods.desertContrast = 0.08

-- Guarida volcánica (CraterMode "lava"): sol bajo de tarde, bruma roja y espesa
-- de humo, sombras rojizas; algo más oscuro que el cráter pero claro para jugar.
SkyMoods.lair =
	mood(0, 1.9, rgb(255, 92, 52), rgb(168, 42, 22), 0.3, rgb(255, 212, 188), rgb(205, 112, 88))
SkyMoods.lairHour = 17
SkyMoods.lairSaturation = 0.18
SkyMoods.lairContrast = 0.16

-- Lago helado (CraterMode "ice"): sol de media tarde, frío, niebla azulada algo
-- más espesa, sombras azules y colores limpios (menos saturados que la lava).
SkyMoods.ice = mood(
	0,
	2.3,
	rgb(198, 226, 248),
	rgb(120, 162, 206),
	0.34,
	rgb(232, 244, 255),
	rgb(158, 186, 218)
)
SkyMoods.iceHour = 14.5
SkyMoods.iceSaturation = 0.04
SkyMoods.iceContrast = 0.1

-- Amanecer del descanso: mañana clara y dorada; el sol sube hasta dawnHour.
SkyMoods.dawn = mood(
	0,
	2.6,
	rgb(255, 226, 196),
	rgb(214, 160, 120),
	0.22,
	rgb(255, 247, 232),
	rgb(175, 160, 145)
)
SkyMoods.dawnHour = 9.5

return SkyMoods
