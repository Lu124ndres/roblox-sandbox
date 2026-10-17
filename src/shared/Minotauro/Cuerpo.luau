--!strict
--[[
	Minotauro/Cuerpo

	Lo que la pose tiene que respetar del cuerpo. Las medidas son de cada etapa
	(Etapas: body, en fracciones del alto, medidas en el modelo de bloques v2 por
	tools/blender/minotauro_v2_pisoton.py):
		plant(pose, body)  baja o sube el cuerpo (dy) para que la parte más baja de las
		             piernas quede en el suelo: al doblar las rodillas se agacha de
		             verdad, al mecerse no hunde un pie y, como la pezuña es un bloque,
		             cuenta el talón o la punta que baja al inclinarse el pie (y el
		             borde de la pierna inclinada). Cuenta la cadera echada atrás (hip):
		             el muslo queda más adelante; sentado, apoya los talones y la cola
		             del cuerpo queda justo encima del suelo. No corre en el aire (air).
		skirt(pose, body)  cuánto tiene que levantarse el faldón de adelante (rad) para
		             que el muslo no lo atraviese; sale de los choques medidos en
		             body.skirt, que toma siempre el mayor hasta ese ángulo para que
		             no baje mientras el muslo sube.
]]

local Etapas = require(script.Parent.Etapas)

local Cuerpo = {}

-- Cuánto baja la parte más baja de la pierna respecto del tobillo, más que en reposo:
-- la pezuña inclinada (foot, + = punta arriba) baja el talón o la punta; la pierna
-- inclinada (shin, + = adelante), su borde de atrás o de adelante.
local function dip(body: Etapas.Body, shin: number, foot: number): number
	local s, c = math.sin(foot), math.cos(foot)
	local hoof = math.max(body.heel * s, -body.toe * s) + body.ankle * c
	local edge = if shin > 0
		then body.shinBack * math.sin(shin)
		else -body.shinFront * math.sin(shin)
	return math.max(hoof, edge) - body.ankle
end

-- Cuánto sube lo más bajo de una pierna (side: +1 su derecha, -1 su izquierda). leg es el
-- muslo con la cadera; foot, la pezuña en el mundo.
local function footRaise(
	body: Etapas.Body,
	leg: number,
	knee: number,
	foot: number,
	sway: number,
	side: number
): number
	local bend = body.thigh * (1 - math.cos(leg)) + body.shin * (1 - math.cos(leg - knee))
	local tilt = body.hip * (1 - math.cos(sway)) - side * body.footSide * math.sin(sway)
	return bend + tilt - dip(body, leg - knee, foot)
end

function Cuerpo.plant(pose: { [string]: number }, body: Etapas.Body)
	local function v(key: string): number
		return pose[key] or 0
	end
	local sway, hip = v("sway"), v("hip")
	local function raise(s: string, side: number): number
		local leg, knee = v("leg" .. s), v("knee" .. s)
		local foot = hip + leg * 0.6 - knee * 0.5 + v("foot" .. s) -- como Pose.apply
		return footRaise(body, leg + hip, knee, foot, sway, side)
	end
	pose.dy = v("dy") - math.min(raise("L", -1), raise("R", 1)) * (1 - math.clamp(v("air"), 0, 1))
end

function Cuerpo.skirt(pose: { [string]: number }, body: Etapas.Body): number
	local skirt = body.skirt
	local thigh = math.deg(math.max(pose.legL or 0, pose.legR or 0, 0))
	for i = 2, #skirt do
		local a, b = skirt[i - 1], skirt[i]
		if thigh <= b[1] then
			return math.rad(a[2] + (b[2] - a[2]) * (thigh - a[1]) / (b[1] - a[1]))
		end
	end
	return math.rad(skirt[#skirt][2])
end

return table.freeze(Cuerpo)
