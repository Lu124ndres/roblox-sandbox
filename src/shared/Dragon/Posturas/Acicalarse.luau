--!strict
--[[
	Acicalarse: gira la cabeza hacia un costado (en arco: el cuello baja y se
	curva, la cabeza llega después), levanta un poco el ala de ese lado y se la
	mordisquea a golpecitos (preen), se sacude y vuelve. El lado sale de la
	semilla.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = { { at = 0.3, kind = "preen" } }

return table.freeze({
	name = "acicalarse",
	seconds = 5.5,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, ctx: Tipos.Ctx): Tipos.Pose
		local side = if (ctx.seed // 2) % 2 == 0 then 1 else -1
		local turn = C.hold(u, 0.05, 0.28, 0.78, 0.94)
		local nibble = C.hold(u, 0.3, 0.34, 0.72, 0.76)
		local peck = math.max(0, math.sin(u * 55)) * nibble
		local shake = math.sin(u * 80) * C.hold(u, 0.8, 0.84, 0.88, 0.92)
		local wing = C.hold(u, 0.18, 0.32, 0.72, 0.86)
		local lifted: Tipos.Pose = {
			look = side * 2.1 * turn,
			neck = -0.25 * turn,
			head = -0.45 * turn - 0.12 * peck,
			tilt = side * 0.3 * turn + 0.15 * shake,
			jaw = 0.15 * nibble + 0.35 * peck,
			tailCurl = side * 0.5 * turn,
			crouch = 0.1 * turn,
		}
		-- El ala de ese lado se abre un poco y sube.
		lifted[if side > 0 then "tuckL" else "tuckR"] = -0.45 * wing
		lifted[if side > 0 then "wingL" else "wingR"] = 0.3 * wing
		return lifted
	end,
} :: Tipos.Behavior)
