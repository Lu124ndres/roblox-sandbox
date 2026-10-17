--!strict
--[[
	Dragon/Comer/Mirar

	Mira a quien le acaba de dar un pez: gira el cuello y la cabeza hacia él y la
	baja si está más abajo (look y head: con resorte en Dragon/Pose, así llega
	suave). Al jugador de este cliente lo mira de lleno; a los demás, a medias.
	Se apaga HOLD s después del último pez.
		bearing(from, center, yaw)  hacia dónde está from respecto del frente
		                            (rad, + a su izquierda) y qué tan arriba (rad)
		add(out, from, age, isLocal, center, yaw)  suma la mirada a la pose out
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)

local HOLD = 2.5 -- s mirando a quien le dio

local Mirar = {}

function Mirar.bearing(from: Vector3, center: Vector3, yaw: number): (number, number)
	local d = from - center
	local rel = (math.atan2(-d.X, -d.Z) - yaw + math.pi) % (2 * math.pi) - math.pi
	return rel, math.atan2(d.Y, math.max(Vector3.new(d.X, 0, d.Z).Magnitude, 1))
end

function Mirar.add(
	out: { [string]: number },
	from: Vector3?,
	age: number,
	isLocal: boolean,
	center: Vector3,
	yaw: number
)
	if not from or age > HOLD + 1 then
		return
	end
	local w = C.smooth(age / 0.3) * (1 - C.smooth(age - HOLD))
	local rel, elev = Mirar.bearing(from, center, yaw)
	local k = if isLocal then 1 else 0.45
	out.look = (out.look or 0) + math.clamp(rel, -1, 1) * 0.9 * k * w
	out.head = (out.head or 0) + math.clamp(elev, -0.8, 0.3) * 0.5 * k * w
end

return table.freeze(Mirar)
