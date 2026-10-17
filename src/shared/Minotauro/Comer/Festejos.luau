--!strict
--[[
	Minotauro/Comer/Festejos

	Los festejos de los combos (Minotauro/Comer dice cuándo: a los 5, 15 y 30
	peces seguidos y después cada 25, con espera entre uno y otro). Toman todo el
	cuerpo (takes = 1: deja de estirar los brazos para comer):
		tambor    5: saca pecho y se toca la panza como un tambor con los dos puños
		          (drum), se echa atrás satisfecho (yum) y suelta un eructo chico
		          adelantando la cabeza (burp)
		puno      15: junta fuerza agachado, revienta con el puño derecho arriba y
		          ruge de gusto con la cabeza atrás (cheer), bombea el puño
		          rebotando en las rodillas y con el otro puño en la cintura
		victoria  30: baila de victoria (rebota y sube los brazos de a uno, happy),
		          levanta la pata y da un pisotón feliz que levanta arena (stomp) y
		          termina con los dos brazos en V rugiendo (cheer)
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local tambor: Tipos.Move = {
	name = "tambor",
	seconds = 2.2,
	prio = 3,
	takes = 1,
	events = {
		{ at = 0.2, kind = "drum" },
		{ at = 0.3, kind = "drum" },
		{ at = 0.4, kind = "drum" },
		{ at = 0.5, kind = "drum" },
		{ at = 0.6, kind = "yum" },
		{ at = 0.84, kind = "burp" },
	},
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local proud = C.hold(u, 0, 0.12, 0.58, 0.7)
		local beat = C.span(u, 0.15, 0.55) * 4 -- cuatro golpes: izquierda, derecha...
		local hitL = if math.floor(beat) % 2 == 0 then C.bell(beat % 1) else 0
		local hitR = if math.floor(beat) % 2 == 1 then C.bell(beat % 1) else 0
		local drum = C.hold(u, 0.12, 0.18, 0.54, 0.58)
		local rest = C.hold(u, 0.58, 0.68, 0.78, 0.84)
		local burp = C.overshoot(C.span(u, 0.8, 0.86)) * (1 - C.smooth(C.span(u, 0.9, 1)))
		return {
			lean = 0.12 * proud + 0.14 * rest - 0.12 * burp,
			breathe = 0.05 * proud - 0.04 * burp,
			lookPitch = 0.25 * proud + 0.2 * rest - 0.15 * burp,
			jaw = 0.3 * drum + 0.15 * rest + 0.8 * burp,
			armL = 0.35 * drum - 0.25 * hitL + 0.25 * rest,
			armR = 0.35 * drum - 0.25 * hitR + 0.25 * rest,
			outL = 0.15 * drum + 0.2 * hitL,
			outR = 0.15 * drum + 0.2 * hitR,
			elbowL = 1.5 * drum - 0.3 * hitL + 1.2 * rest,
			elbowR = 1.5 * drum - 0.3 * hitR + 1.2 * rest,
			tilt = 0.08 * (hitL - hitR),
			earL = 0.4 * proud - 0.3 * burp,
			earR = 0.4 * proud - 0.3 * burp,
			tail1 = 0.5 * math.sin(u * 24) * proud,
			tailUp = 0.3 * proud,
		}
	end,
}

local puno: Tipos.Move = {
	name = "puno",
	seconds = 2.4,
	prio = 3,
	takes = 1,
	events = { { at = 0.27, kind = "cheer" } },
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local gather = C.hold(u, 0, 0.18, 0.2, 0.26)
		local up = C.overshoot(C.span(u, 0.22, 0.32)) * (1 - C.smooth(C.span(u, 0.82, 0.97)))
		local roar = C.hold(u, 0.26, 0.32, 0.55, 0.68)
		local pump = math.max(0, math.sin(C.span(u, 0.5, 0.86) * math.pi * 6)) * up
		return {
			lean = -0.15 * gather + 0.15 * up,
			lookPitch = -0.25 * gather + 0.4 * roar + 0.15 * up,
			jaw = 1.0 * roar + 0.25 * pump,
			armR = 0.3 * gather + 2.5 * up - 0.25 * pump,
			outR = 0.25 * up,
			elbowR = 1.2 * gather + 0.15 * up + 0.5 * pump,
			armL = 0.3 * gather,
			outL = 0.5 * up,
			elbowL = 1.3 * gather,
			elbowOutL = -1.1 * up, -- la mano a la cintura (como al rascarse)
			legL = 0.35 * gather + 0.12 * pump,
			legR = 0.35 * gather + 0.12 * pump,
			kneeL = 0.7 * gather + 0.35 * pump,
			kneeR = 0.7 * gather + 0.35 * pump,
			lookYaw = -0.2 * up, -- mira el puño
			earL = 0.3 * gather - 0.5 * roar,
			earR = 0.3 * gather - 0.5 * roar,
			tailUp = -0.2 * gather + 0.7 * up,
		}
	end,
}

local victoria: Tipos.Move = {
	name = "victoria",
	seconds = 3.4,
	prio = 3,
	takes = 1,
	events = {
		{ at = 0.04, kind = "happy" },
		{ at = 0.62, kind = "stomp" },
		{ at = 0.72, kind = "cheer" },
	},
	pose = function(u: number, _ctx: Tipos.Ctx): Pose.Pose
		local dance = C.hold(u, 0, 0.06, 0.44, 0.5)
		local phase = C.span(u, 0, 0.5) * math.pi * 8
		local beat, bob = math.sin(phase), math.abs(math.sin(phase))
		local lift = C.smooth(C.span(u, 0.48, 0.58)) * (1 - C.easeIn(C.span(u, 0.58, 0.62)))
		local hit = C.decay(u, 0.62, 10) * (1 - C.smooth(C.span(u, 0.75, 0.85)))
		local v = C.overshoot(C.span(u, 0.66, 0.76)) * (1 - C.smooth(C.span(u, 0.88, 1)))
		local roar = C.hold(u, 0.7, 0.76, 0.86, 0.95)
		return {
			sway = 0.14 * beat * dance - 0.1 * lift,
			tilt = 0.22 * beat * dance,
			lookPitch = 0.1 * bob * dance + 0.15 * lift - 0.3 * hit + 0.4 * roar,
			lean = 0.08 * lift - 0.2 * hit + 0.1 * v,
			armL = (1.8 + 0.6 * beat) * dance + 0.3 * lift - 0.2 * hit + 2.3 * v,
			armR = (1.8 - 0.6 * beat) * dance + 0.3 * lift - 0.2 * hit + 2.3 * v,
			outL = 0.4 * dance + 0.6 * lift + 0.6 * v,
			outR = 0.4 * dance + 0.6 * lift + 0.6 * v,
			elbowL = 0.5 * dance + 0.3 * lift,
			elbowR = 0.5 * dance + 0.3 * lift,
			legL = 0.3 * bob * dance + 0.35 * hit,
			legR = 0.3 * bob * dance + 0.95 * lift + 0.35 * hit,
			kneeL = 0.6 * bob * dance + 0.7 * hit,
			kneeR = 0.6 * bob * dance + 1.1 * lift + 0.7 * hit,
			jaw = 0.3 * dance + 0.5 * hit + 1.0 * roar,
			earL = 0.3 * bob * dance - 0.5 * roar,
			earR = 0.3 * bob * dance - 0.5 * roar,
			tail1 = 0.5 * beat * dance,
			tail2 = 0.6 * beat * dance,
			tailUp = 0.4 * lift + 0.6 * v,
		}
	end,
}

return table.freeze({
	tambor = table.freeze(tambor),
	puno = table.freeze(puno),
	victoria = table.freeze(victoria),
})
