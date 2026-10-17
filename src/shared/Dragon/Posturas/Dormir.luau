--!strict
--[[
	Dormir: dura lo que le quede de la estadía (ctx.seconds). Gira y baja la
	cabeza (anticipación), se echa enroscándose: patas dobladas con la panza en
	la roca, el cuello curvado hacia un costado con la cabeza junto a la cadera y
	la cola dando la vuelta del otro lado (sleep cuando termina de acomodarse);
	duerme respirando hondo y lento, con algún respingo de la cola. Al final
	despierta (wake): levanta la cabeza primero, bosteza abriendo un poco las
	alas, se sacude y se pone de pie. Curl y wake tardan más cuanto más grande.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)
local Tipos = require(script.Parent.Tipos)

local CURL, WAKE = 3.2, 3.4 -- s (por el pace de la etapa)

local function parts(ctx: Tipos.Ctx): (number, number)
	local total = math.max(ctx.seconds, 1)
	local pace = ctx.profile.pace
	return math.min(CURL * pace / total, 0.45), math.min(WAKE * pace / total, 0.45)
end

return table.freeze({
	name = "dormir",
	seconds = 20,
	events = function(ctx: Tipos.Ctx): { Tipos.Event }
		local curl, wake = parts(ctx)
		return { { at = curl, kind = "sleep" }, { at = 1 - wake, kind = "wake" } }
	end,
	pose = function(u: number, ctx: Tipos.Ctx): Tipos.Pose
		local curl, wake = parts(ctx)
		local side = if (ctx.seed // 4) % 2 == 0 then 1 else -1
		local t = u * ctx.seconds
		local w0 = 1 - wake
		local down = C.smooth(C.span(u, curl * 0.25, curl))
			* (1 - C.smooth(C.span(u, w0 + wake * 0.35, 1)))
		local glance = C.bell(C.span(u, 0, curl * 0.4)) -- mira dónde echarse
		local head = C.smooth(C.span(u, w0, w0 + wake * 0.35))
			* (1 - C.smooth(C.span(u, w0 + wake * 0.6, 1)))
		local yawn = C.hold(u, w0 + wake * 0.2, w0 + wake * 0.35, w0 + wake * 0.5, w0 + wake * 0.65)
		local shake = math.sin(t * 25)
			* C.hold(u, w0 + wake * 0.65, w0 + wake * 0.7, w0 + wake * 0.8, w0 + wake * 0.85)
		local sleeping = C.hold(u, curl * 0.8, curl, w0, w0 + wake * 0.2)
		local breath = math.sin(t * 2 * math.pi / (4.5 * ctx.profile.pace)) * sleeping
		local twitch = math.max(0, math.sin(t * 0.9)) ^ 12 * sleeping
		return {
			crouch = 1.5 * down,
			pitch = -0.2 * down,
			look = side * (0.5 * glance + 2.3 * down) - side * 1.6 * head,
			neck = -0.2 * glance - 0.5 * down + 0.4 * head,
			head = -0.35 * down + 0.4 * head + 0.2 * yawn,
			tilt = side * 0.3 * down + 0.1 * shake,
			tailCurl = -side * 1.8 * down + 0.3 * twitch,
			tailDroop = -0.6 * down,
			calm = sleeping,
			chest = 0.05 * breath,
			jaw = 1.0 * yawn,
			tuck = -0.6 * yawn,
			spread = 0.35 * yawn,
		}
	end,
} :: Tipos.Behavior)
