--!strict
--[[
	Minotauro/Cuerpo

	Lo que la pose tiene que respetar del cuerpo (medidas en fracciones del alto,
	del modelo de bloques v2: tools/blender/minotauro_v2_e1_poses.py):
		plant(pose)  baja o sube el cuerpo (dy) para que el pie más bajo quede en
		             el suelo: al doblar las rodillas se agacha de verdad y al
		             mecerse no hunde un pie. No corre en el aire (air = 1).
		skirt(pose)  cuánto tiene que levantarse el faldón de adelante (rad) para
		             que el muslo no lo atraviese; sale de los choques medidos en
		             renders/minotauro_v2_e1/pisoton.json (curva_muslo_faldon),
		             tomando siempre el mayor hasta ese ángulo para que no baje
		             mientras el muslo sube.
]]

local THIGH = 0.13 -- largo del muslo (cadera a rodilla)
local SHIN = 0.13 -- largo de la pierna (rodilla al tobillo)
local HIP = 0.32 -- alto de la cadera
local FOOT_SIDE = 0.1 -- distancia de cada pie al centro

-- Muslo (grados) -> faldón (grados), creciente.
local SKIRT: { { number } } = {
	{ 0, 0 },
	{ 40, 15 },
	{ 45, 28 },
	{ 48, 47 },
	{ 50, 67 },
	{ 52, 71 },
	{ 90, 91 },
}

local Cuerpo = {}

-- Cuánto sube el pie de un lado (side: +1 su derecha, -1 su izquierda).
local function footRaise(leg: number, knee: number, sway: number, side: number): number
	local bend = THIGH * (1 - math.cos(leg)) + SHIN * (1 - math.cos(leg - knee))
	local tilt = HIP * (1 - math.cos(sway)) - side * FOOT_SIDE * math.sin(sway)
	return bend + tilt
end

function Cuerpo.plant(pose: { [string]: number })
	local function v(key: string): number
		return pose[key] or 0
	end
	local sway = v("sway")
	local left = footRaise(v("legL"), v("kneeL"), sway, -1)
	local right = footRaise(v("legR"), v("kneeR"), sway, 1)
	pose.dy = v("dy") - math.min(left, right) * (1 - math.clamp(v("air"), 0, 1))
end

function Cuerpo.skirt(pose: { [string]: number }): number
	local thigh = math.deg(math.max(pose.legL or 0, pose.legR or 0, 0))
	for i = 2, #SKIRT do
		local a, b = SKIRT[i - 1], SKIRT[i]
		if thigh <= b[1] then
			return math.rad(a[2] + (b[2] - a[2]) * (thigh - a[1]) / (b[1] - a[1]))
		end
	end
	return math.rad(SKIRT[#SKIRT][2])
end

return table.freeze(Cuerpo)
