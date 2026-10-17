--!strict
--[[
	Minotauro/Etapas

	Cómo se mueve cada etapa del minotauro (modelo MinotauroE1..E4):
		breathe    segundos por respiración (el becerro respira rápido, el
		           gigante lento y hondo)
		tail       segundos por vaivén de la cola
		turnSpeed  rad/s como mucho al darse vuelta
		sway       cuánto se mece (multiplica el vaivén y la respiración)
		voice      tono del rugido (agudo > 1, grave < 1)
		stomp      fuerza del pisotón y de la caída: temblor y tamaño de la ola
		tricks     los trucos que hace (Minotauro/Trucos) y cada cuántos segundos
		pace       cuánto más lentos son sus trucos y sus resortes (1 = becerro)
		bounce     amortiguación de los resortes (Minotauro/Resortes): baja rebota,
		           alta se queda quieta enseguida
		body       medidas del cuerpo para Minotauro/Cuerpo, en fracciones del alto
		           (renders/minotauro_v2_e<n>/medidas.json, del modelo de bloques v2):
		           thigh y shin (largo del muslo y de la pierna), hip (alto de la
		           cadera), footSide (pie al centro) y skirt (muslo -> faldón, grados)
]]

export type Body = {
	thigh: number,
	shin: number,
	hip: number,
	footSide: number,
	skirt: { { number } },
}

export type Profile = {
	breathe: number,
	tail: number,
	turnSpeed: number,
	sway: number,
	voice: number,
	stomp: number,
	tricks: { string },
	trickEvery: number,
	pace: number,
	bounce: number,
	body: Body,
}

-- Medidas del v2 E1 (minotauro_v2_pisoton.py). Las etapas que todavía no tienen su v2 usan
-- estas: el muslo y la pierna miden casi lo mismo en todas (minotauro_etapas.py las estira
-- parecido).
local BODY_E1: Body = {
	thigh = 0.129,
	shin = 0.129,
	hip = 0.3226,
	footSide = 0.0968,
	skirt = { { 0, 0 }, { 40, 15 }, { 45, 28 }, { 48, 47 }, { 50, 67 }, { 52, 71 }, { 90, 91 } },
}

local PROFILES: { [number]: Profile } = {
	{ -- becerro: inquieto, baila y salta
		breathe = 2.6,
		tail = 1.8,
		turnSpeed = 1.3,
		sway = 1.2,
		voice = 1.35,
		stomp = 0.7,
		tricks = { "baile", "salto", "pisoton", "rugido", "baile", "musculo", "salto", "rascarse" },
		trickEvery = 11,
		pace = 1,
		bounce = 0.28,
		body = BODY_E1,
	},
	{ -- joven: fanfarrón, saca músculo y todavía baila
		breathe = 3,
		tail = 2.1,
		turnSpeed = 1.15,
		sway = 1,
		voice = 1.1,
		stomp = 0.9,
		tricks = { "pisoton", "musculo", "baile", "rugido", "salto", "rascarse" },
		trickEvery = 12,
		pace = 1.1,
		bounce = 0.38,
		body = BODY_E1,
	},
	{ -- adulto: pesado, pisa y ruge
		breathe = 3.5,
		tail = 2.5,
		turnSpeed = 0.95,
		sway = 0.85,
		voice = 0.88,
		stomp = 1.15,
		tricks = { "pisoton", "rugido", "musculo", "salto", "pisoton", "rascarse" },
		trickEvery = 13,
		pace = 1.25,
		bounce = 0.5,
		body = BODY_E1,
	},
	{ -- forma final: enorme y lento; ruge y pisa, ya no baila ni salta
		breathe = 4.2,
		tail = 3,
		turnSpeed = 0.75,
		sway = 0.7,
		voice = 0.7,
		stomp = 1.5,
		tricks = { "rugido", "pisoton", "musculo", "pisoton", "rugido", "rascarse" },
		trickEvery = 14,
		pace = 1.45,
		bounce = 0.65,
		body = BODY_E1,
	},
}

local Etapas = {}

-- La etapa sale del nombre del modelo (…E1 … E4, o …E1_v2 del modelo de bloques);
-- sin modelo, el becerro.
function Etapas.forModel(name: string?): Profile
	local digit = if name
		then string.match(name, "E(%d)_v%d+$") or string.match(name, "E(%d)$")
		else nil
	local stage = tonumber(digit)
	return PROFILES[math.clamp(stage or 1, 1, #PROFILES)]
end

return table.freeze(Etapas)
