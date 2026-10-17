--!strict
--[[
	Minotauro/Cuerpo

	Lo que la pose tiene que respetar del cuerpo. Las medidas son de cada etapa
	(Etapas: body, en fracciones del alto, medidas en el modelo de bloques v2 por
	tools/blender/minotauro_v2_pisoton.py):
		plant(pose, body)  baja o sube el cuerpo (dy) para que el pie más bajo quede en
		             el suelo: al doblar las rodillas se agacha de verdad y al
		             mecerse no hunde un pie. No corre en el aire (air = 1).
		skirt(pose, body)  cuánto tiene que levantarse el faldón de adelante (rad) para
		             que el muslo no lo atraviese; sale de los choques medidos en
		             body.skirt, que toma siempre el mayor hasta ese ángulo para que
		             no baje mientras el muslo sube.
]]

local Etapas = require(script.Parent.Etapas)

local Cuerpo = {}

-- Cuánto sube el pie de un lado (side: +1 su derecha, -1 su izquierda).
local function footRaise(
	body: Etapas.Body,
	leg: number,
	knee: number,
	sway: number,
	side: number
): number
	local bend = body.thigh * (1 - math.cos(leg)) + body.shin * (1 - math.cos(leg - knee))
	local tilt = body.hip * (1 - math.cos(sway)) - side * body.footSide * math.sin(sway)
	return bend + tilt
end

function Cuerpo.plant(pose: { [string]: number }, body: Etapas.Body)
	local function v(key: string): number
		return pose[key] or 0
	end
	local sway = v("sway")
	local left = footRaise(body, v("legL"), v("kneeL"), sway, -1)
	local right = footRaise(body, v("legR"), v("kneeR"), sway, 1)
	pose.dy = v("dy") - math.min(left, right) * (1 - math.clamp(v("air"), 0, 1))
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
