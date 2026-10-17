--!strict
--[[
	Posarse: lo primero al tocar la roca (land). Llega con las patas estiradas,
	el cuerpo levantado y las alas abiertas (como lo deja Posturas/Aire al
	frenar); el peso lo aplasta (patas dobladas, cabeza que sigue bajando),
	rebota según la etapa (la cría mucho, la anciana casi nada), sacude las alas
	y las pliega sobre el lomo (fold) y se acomoda mirando al frente.
	Se suma a Posturas.base, que ya tiene las alas plegadas: aquí se despliegan
	(tuck negativo) y se van plegando.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local EVENTS: { Tipos.Event } = { { at = 0, kind = "land" }, { at = 0.42, kind = "fold" } }

return table.freeze({
	name = "posarse",
	seconds = 1.9,
	events = function(_ctx: Tipos.Ctx): { Tipos.Event }
		return EVENTS
	end,
	pose = function(u: number, ctx: Tipos.Ctx): Tipos.Pose
		local bounce = ctx.profile.bounce
		local open = 1 - C.smooth(C.span(u, 0.2, 0.62))
		local impact = C.decay(u, 0, 7) * (1 - C.span(u, 0.85, 1))
		local rebound = C.bell(C.span(u, 0.16, 0.42)) * bounce
		local flutter = math.sin(u * 45) * C.hold(u, 0.25, 0.3, 0.4, 0.48)
		return {
			crouch = 1.0 * impact - 0.25 * rebound,
			pitch = 0.5 * (1 - C.smooth(C.span(u, 0, 0.3))),
			reach = 1 - C.smooth(C.span(u, 0, 0.12)),
			tuck = -1 * open,
			spread = 0.5 * open - 0.25 * impact,
			wingL = 0.1 * flutter,
			wingR = 0.1 * flutter,
			neck = -0.35 * impact + 0.15 * rebound,
			head = -0.3 * impact + 0.1 * rebound,
			jaw = 0.25 * impact,
			tailUp = 0.5 * impact - 0.3 * rebound,
		}
	end,
} :: Tipos.Behavior)
