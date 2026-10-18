--!strict
--[[
	Zorro/Rutina/Reserva

	Las conductas de reserva: las usa Rutina solo si Zorro/Conductas no está o
	viene vacía (así el zorro nunca se queda sin rutina mientras se arma el
	catálogo). Tres posturas simples y los trucos de Zorro/Trucos:
		olfatear   baja el hocico al hielo y olfatea dos veces (sniff)
		sentarse   se sienta y mira, con las colas envolviendo las patas
		bostezar   abre grande la boca y echa las orejas (yawn)
		trucos     los de Zorro/Trucos (aullido, abanico, salto, sacudida,
		           reverencia, fuegos), de frente a la puerta. Trucos no expone su
		           tabla: se toman de Trucos.current en el arranque de cada tramo
		           (EVERY y el retraso de Trucos, 13 s y 30 %).
]]

local Tipos = require(script.Parent.Parent.Tipos)
local Trucos = require(script.Parent.Parent.Trucos)

local TRICK_EVERY, TRICK_DELAY = 13, 0.3 -- los de Zorro/Trucos
local TRICK_WEIGHTS: { [string]: { number } } = {
	aullido = { 0, 0, 1, 1 },
	abanico = { 0, 1, 1, 1 },
	salto = { 1.2, 1, 0.6, 0 },
	sacudida = { 1, 1, 1, 1 },
	reverencia = { 1.2, 1, 0.8, 0.5 },
	fuegos = { 0.5, 0.8, 1, 1 },
}

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Sube en [a, b], se queda y baja en [c, d] (u de 0 a 1).
local function hold(u: number, a: number, b: number, c: number, d: number): number
	return smooth((u - a) / (b - a)) * (1 - smooth((u - c) / (d - c)))
end

local lista: { Tipos.Conducta } = {
	{
		nombre = "olfatear",
		tipo = "postura",
		pesos = { 1, 1, 1, 0.5 },
		quieto = true,
		eventos = { { at = 0.3, kind = "sniff" }, { at = 0.6, kind = "sniff" } },
		duracion = function(etapa: number, r: number): number
			return (2.6 + 1.2 * r) * (0.85 + 0.15 * etapa)
		end,
		pose = function(u: number): Tipos.Pose
			local f = hold(u, 0, 0.25, 0.8, 1)
			local sniff = math.sin(u * math.pi * 14) * 0.03 * f
			return {
				lookPitch = -0.55 * f + sniff,
				lean = -0.1 * f,
				earL = 0.3 * f,
				earR = 0.25 * f,
				tailLift = 0.15 * f,
				lookHold = f,
			}
		end,
	},
	{
		nombre = "sentarse",
		tipo = "postura",
		pesos = { 0.6, 1, 1.2, 1.5 },
		quieto = true,
		eventos = {},
		duracion = function(etapa: number, r: number): number
			return (4 + 3 * r) * (0.8 + 0.2 * etapa)
		end,
		pose = function(u: number): Tipos.Pose
			local f = hold(u, 0, 0.2, 0.82, 1)
			return { sit = f, lean = 0.12 * f, lookPitch = 0.12 * f, tailWrap = f, earL = 0.2 * f }
		end,
	},
	{
		nombre = "bostezar",
		tipo = "postura",
		pesos = { 1, 1, 1, 1 },
		quieto = true,
		eventos = { { at = 0.3, kind = "yawn" } },
		duracion = function(etapa: number, r: number): number
			return (2.2 + 0.6 * r) * (0.85 + 0.15 * etapa)
		end,
		pose = function(u: number): Tipos.Pose
			local f = hold(u, 0.1, 0.35, 0.65, 0.9)
			return {
				jaw = 1 * f,
				lookPitch = 0.3 * f,
				earL = -0.5 * f,
				earR = -0.45 * f,
				eyesClosed = 0.8 * f,
				emoSueno = f,
			}
		end,
	},
}

local seen: { [string]: boolean } = {}
for slot = 0, 63 do
	local trick = Trucos.current(slot * TRICK_EVERY + TRICK_EVERY * TRICK_DELAY + 0.01)
	if trick and not seen[trick.name] and TRICK_WEIGHTS[trick.name] then
		seen[trick.name] = true
		local events: { Tipos.Evento } = {}
		for _, event in trick.events do
			table.insert(events, { at = event.at, kind = event.kind })
		end
		table.insert(lista, {
			nombre = trick.name,
			tipo = "truco",
			pesos = TRICK_WEIGHTS[trick.name],
			quieto = true,
			eventos = events,
			duracion = function(): number
				return trick.seconds
			end,
			pose = function(u: number): Tipos.Pose
				return trick.pose(u)
			end,
		})
	end
end

return table.freeze(lista)
