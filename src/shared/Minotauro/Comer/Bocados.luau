--!strict
--[[
	Minotauro/Comer/Bocados

	Lo que hace con un pez común (Minotauro/Comer elige uno cada tanto, no uno
	por pez: llegan cada ~0.2 s). Todas tienen anticipación, impacto sin suavizar
	y rebote al llegar; orejas y cola las sigue Resortes:
		atrapa  con la boca: echa la cabeza atrás abriendo grande, se tira adelante,
		        cierra de golpe y traga echando la cabeza atrás (gulp)
		manos   abre los brazos, aplaude para atraparlo (clap) agachándose, se lo
		        lleva a la boca con las dos manos y traga (gulp). Se usa cuando el
		        pez viene de un costado (Comer la refleja hacia ese lado)
		panza   traga con la cabeza atrás y el pecho afuera (gulp) y se palmea la
		        panza dos veces con la mano (pat), contento, moviendo la cola
		gusto   le encanta: se sacude de gusto ladeando la cabeza, para las orejas,
		        mueve la cola rápido y (si su etapa salta) da un saltito (yum)
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local atrapa: Tipos.Move = {
	name = "atrapa",
	seconds = 0.75,
	prio = 1,
	takes = 0.35,
	events = { { at = 0.5, kind = "gulp" } },
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local back = C.hold(u, 0, 0.18, 0.2, 0.3)
		local open = C.hold(u, 0.02, 0.2, 0.3, 0.34)
		local lunge = C.smooth(C.span(u, 0.2, 0.32)) * (1 - C.smooth(C.span(u, 0.36, 0.55)))
		local shut = C.hold(u, 0.32, 0.35, 0.7, 0.95)
		local gulp = C.overshoot(C.span(u, 0.42, 0.6)) * (1 - C.smooth(C.span(u, 0.72, 1)))
		return {
			lookPitch = 0.14 * back - 0.3 * lunge + 0.26 * gulp,
			lean = 0.04 * back - 0.1 * lunge + 0.05 * gulp,
			jaw = 0.9 * open - 0.7 * shut,
			breathe = 0.05 * gulp,
			earL = 0.3 * open + 0.2 * gulp,
			earR = 0.3 * open + 0.2 * gulp,
			tailUp = 0.2 * gulp,
		}
	end,
}

local manos: Tipos.Move = {
	name = "manos",
	seconds = 0.95,
	prio = 1,
	takes = 0.85,
	events = { { at = 0.3, kind = "clap" }, { at = 0.64, kind = "gulp" } },
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local wide = C.hold(u, 0, 0.18, 0.2, 0.28)
		local catch = C.overshoot(C.span(u, 0.2, 0.3)) * (1 - C.smooth(C.span(u, 0.32, 0.45)))
		local mouth = C.hold(u, 0.32, 0.5, 0.62, 0.92)
		local open = C.hold(u, 0.36, 0.48, 0.56, 0.62)
		local gulp = C.bell(C.span(u, 0.6, 0.88))
		local dip = C.decay(u, 0.3, 12) * (1 - C.smooth(C.span(u, 0.5, 0.7)))
		local arm = 0.5 * wide + 1.15 * catch + 1.4 * mouth
		local elbow = 0.3 * wide + 0.5 * catch + 1.5 * mouth
		return {
			armL = arm,
			armR = arm,
			outL = 0.95 * wide - 0.25 * catch + 0.05 * mouth,
			outR = 0.95 * wide - 0.25 * catch + 0.05 * mouth,
			elbowL = elbow,
			elbowR = elbow,
			lookYaw = 0.3 * wide + 0.15 * catch, -- hacia el lado de donde viene
			sway = 0.05 * wide,
			lean = 0.06 * wide - 0.08 * dip + 0.03 * gulp,
			lookPitch = 0.1 * wide - 0.1 * mouth + 0.24 * gulp,
			jaw = 0.8 * open - 0.5 * gulp,
			legL = 0.15 * dip,
			legR = 0.15 * dip,
			kneeL = 0.3 * dip,
			kneeR = 0.3 * dip,
			earL = 0.35 * wide + 0.2 * gulp,
			earR = 0.35 * wide + 0.2 * gulp,
			tail1 = 0.4 * math.sin(u * 30) * gulp,
		}
	end,
}

local panza: Tipos.Move = {
	name = "panza",
	seconds = 1.1,
	prio = 1,
	takes = 0.75,
	events = {
		{ at = 0.22, kind = "gulp" },
		{ at = 0.55, kind = "pat" },
		{ at = 0.75, kind = "pat" },
	},
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local gulp = C.overshoot(C.span(u, 0.05, 0.25)) * (1 - C.smooth(C.span(u, 0.35, 0.6)))
		local hand = C.hold(u, 0.28, 0.45, 0.85, 1)
		local lift = C.bell(C.span(u, 0.46, 0.55)) + C.bell(C.span(u, 0.66, 0.75))
		local slap = C.decay(u, 0.55, 25) + C.decay(u, 0.75, 25)
		local wag = math.sin(u * 26) * hand
		return {
			lookPitch = 0.3 * gulp - 0.06 * hand + 0.05 * slap,
			lean = 0.08 * gulp + 0.04 * hand,
			breathe = 0.05 * gulp - 0.02 * slap,
			jaw = -0.5 * gulp + 0.2 * hand,
			armL = 0.3 * hand + 0.15 * lift,
			outL = -0.1 * hand,
			elbowL = 1.2 * hand - 0.35 * lift,
			tilt = 0.12 * hand,
			earL = 0.3 * hand,
			earR = 0.3 * hand,
			tail1 = 0.45 * wag,
			tail2 = 0.5 * wag,
			tailUp = 0.25 * hand,
		}
	end,
}

local gusto: Tipos.Move = {
	name = "gusto",
	seconds = 0.9,
	prio = 1,
	takes = 0.3,
	events = { { at = 0.18, kind = "yum" } },
	pose = function(u: number, ctx: Tipos.Ctx): Pose.Pose
		local f = C.hold(u, 0, 0.15, 0.75, 1)
		local shake = math.sin(C.span(u, 0.1, 0.8) * math.pi * 4) * f
		local load = C.bell(C.span(u, 0.05, 0.25))
		local hop = ctx.hop * C.arc(C.span(u, 0.25, 0.5))
		local land = C.decay(u, 0.5, 14) * (1 - C.smooth(C.span(u, 0.7, 0.9)))
		local bend = 0.5 * load + 0.45 * land
		return {
			tilt = 0.22 * shake,
			sway = 0.05 * shake,
			lookPitch = 0.12 * f,
			jaw = 0.25 * f,
			earL = 0.6 * f,
			earR = 0.6 * f,
			tail1 = 0.6 * math.sin(u * 40) * f,
			tail2 = 0.6 * math.sin(u * 40 - 0.7) * f,
			tailUp = 0.35 * f,
			dy = 0.05 * hop,
			air = if hop > 0.05 then 1 else 0,
			legL = 0.25 * bend,
			legR = 0.25 * bend,
			kneeL = bend,
			kneeR = bend,
		}
	end,
}

return table.freeze({
	atrapa = table.freeze(atrapa),
	manos = table.freeze(manos),
	panza = table.freeze(panza),
	gusto = table.freeze(gusto),
})
