--!strict
--[[
	Minotauro/Posturas/Mirar

	Dos posturas para mirar:
		cielo    baja un poco la cabeza (anticipación) y mira al cielo echándose
		         atrás, con las orejas paradas y la boca entreabierta; recorre el
		         cielo despacio de un lado al otro y vuelve
		jugador  se da vuelta hacia alguien (looks: init gira el cuerpo hacia
		         Posturas.lookAt), ladea la cabeza con curiosidad, para las orejas
		         y lo saluda con un cabezazo y un resoplido (snort)
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local NO_EVENTS: { Tipos.Event } = {}
local GREET: { Tipos.Event } = { { at = 0.64, kind = "snort" } }

local cielo: Tipos.Behavior = {
	name = "mirarCielo",
	seconds = 5,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return NO_EVENTS
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local dip = C.hold(u, 0, 0.06, 0.08, 0.14)
		local up = C.hold(u, 0.1, 0.26, 0.78, 0.94)
		local scan = math.sin(C.span(u, 0.3, 0.75) * math.pi * 2) * up
		return {
			lookPitch = -0.1 * dip + 0.55 * up,
			lean = 0.22 * up,
			lookYaw = 0.35 * scan,
			tilt = 0.1 * scan,
			jaw = 0.18 * up,
			earL = 0.3 * up,
			earR = 0.3 * up,
			outL = 0.2 * up,
			outR = 0.2 * up,
			tailUp = 0.15 * up,
		}
	end,
}

local jugador: Tipos.Behavior = {
	name = "mirarJugador",
	seconds = 5,
	looks = true,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return GREET
	end,
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local look = C.hold(u, 0.05, 0.25, 0.85, 0.98)
		local tilt = C.overshoot(C.span(u, 0.25, 0.4)) * (1 - C.smooth(C.span(u, 0.55, 0.62)))
		local toss = C.hold(u, 0.56, 0.6, 0.6, 0.64) -- baja la cabeza (anticipación)
		local greet = C.decay(u, 0.64, 18) * (1 - C.smooth(C.span(u, 0.85, 0.98)))
		return {
			tilt = 0.25 * tilt,
			lookPitch = 0.1 * look - 0.2 * toss + 0.3 * greet,
			jaw = 0.1 * look + 0.25 * greet,
			earL = 0.45 * look,
			earR = 0.45 * look,
			tail1 = 0.4 * math.sin(u * 28) * greet,
			tailUp = 0.25 * greet,
		}
	end,
}

return table.freeze({ cielo = table.freeze(cielo), jugador = table.freeze(jugador) })
