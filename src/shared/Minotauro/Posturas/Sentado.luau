--!strict
--[[
	Minotauro/Posturas/Sentado

	Lo que hace mientras está sentado (Posturas/Sentarse elige dos por vez con la
	semilla). Cada una recibe su avance v (0..1) y da lo que se suma a la postura
	de sentado; event dice en qué v suena algo:
		rascarse  lleva la mano derecha a la cabeza (llega con rebote) y se rasca;
		          le da gusto: ladea la cabeza y menea la cola
		bostezo   toma aire encogiéndose, se estira hacia atrás con los brazos
		          abiertos y la boca bien abierta, y sacude la cabeza al soltarse
		mirar     mira a un lado y al otro con curiosidad (orejas paradas)
		siesta    cabecea hasta quedarse dormido y se despierta de golpe con un
		          resoplido (solo las etapas con rutina.siesta)
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)

export type Activity = { event: { at: number, kind: string }?, pose: (v: number) -> Pose.Pose }

local ACTIVITIES: { [string]: Activity } = {
	rascarse = {
		event = nil,
		pose = function(v: number): Pose.Pose
			local f = C.hold(v, 0.05, 0.25, 0.8, 0.97)
			local reach = C.overshoot(C.span(v, 0.05, 0.25)) * (1 - C.smooth(C.span(v, 0.8, 0.97)))
			local scratch = math.sin(v * 60) * f
			local relief = C.hold(v, 0.35, 0.45, 0.75, 0.85)
			local tap = math.max(0, math.sin(v * 45)) * relief
			return {
				armR = 0.7 * reach,
				outR = 0.45 * reach,
				elbowR = 0.75 * reach + 0.15 * scratch,
				armL = -0.5 * f,
				tilt = -0.25 * f - 0.05 * relief,
				lookPitch = -0.1 * f,
				jaw = 0.25 * relief,
				earL = 0.3 * f,
				tail2 = 0.3 * tap,
				tail3 = 0.3 * math.sin(v * 25) * relief,
			}
		end,
	},
	bostezo = {
		event = { at = 0.3, kind = "yawn" },
		pose = function(v: number): Pose.Pose
			local inhale = C.hold(v, 0, 0.2, 0.22, 0.3)
			local stretch = C.hold(v, 0.22, 0.42, 0.62, 0.82)
			local open = C.hold(v, 0.25, 0.35, 0.6, 0.75)
			local shake = math.sin(v * 55) * C.hold(v, 0.72, 0.78, 0.86, 0.92)
			return {
				lean = -0.08 * inhale + 0.35 * stretch,
				lookPitch = -0.1 * inhale + 0.4 * stretch,
				lookYaw = 0.2 * shake,
				jaw = 0.2 * inhale + 1.2 * open,
				armL = -0.4 * stretch,
				armR = -0.4 * stretch,
				outL = 1.2 * stretch,
				outR = 1.2 * stretch,
				elbowL = -0.9 * stretch,
				elbowR = -0.9 * stretch,
				elbowOutL = 0.5 * stretch,
				elbowOutR = 0.5 * stretch,
				earL = 0.5 * stretch,
				earR = 0.5 * stretch,
			}
		end,
	},
	mirar = {
		event = nil,
		pose = function(v: number): Pose.Pose
			local f = C.hold(v, 0.05, 0.2, 0.8, 0.95)
			local side = math.sin(v * math.pi * 2)
			return {
				lookYaw = 0.75 * side * f,
				tilt = 0.2 * side * f,
				lookPitch = 0.15 * f,
				earL = 0.4 * f,
				earR = 0.4 * f,
			}
		end,
	},
	siesta = {
		event = { at = 0.8, kind = "snort" },
		pose = function(v: number): Pose.Pose
			local doze = C.smooth(C.span(v, 0.05, 0.45)) * (1 - C.smooth(C.span(v, 0.8, 0.84)))
			local nod = 0.06 * math.sin(v * 9) * doze
			local wake = C.decay(v, 0.8, 14) * (1 - C.smooth(C.span(v, 0.9, 1)))
			return {
				lookPitch = -0.25 * doze + nod + 0.3 * wake,
				lean = -0.12 * doze,
				tilt = 0.2 * doze,
				breathe = 0.03 * math.sin(v * 12) * doze,
				jaw = 0.15 * doze + 0.2 * wake,
				armL = -0.2 * doze,
				armR = -0.2 * doze,
				earL = -0.35 * doze + 0.6 * wake,
				earR = -0.35 * doze + 0.6 * wake,
			}
		end,
	},
}

local Sentado = {}

-- Lo que puede hacer sentado una etapa (la siesta, solo si la etapa dormita).
function Sentado.names(siesta: boolean): { string }
	return if siesta
		then { "rascarse", "bostezo", "mirar", "siesta" }
		else { "rascarse", "bostezo", "mirar" }
end

function Sentado.get(name: string): Activity
	return ACTIVITIES[name]
end

return table.freeze(Sentado)
