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
]]

export type Profile = {
	breathe: number,
	tail: number,
	turnSpeed: number,
	sway: number,
	voice: number,
	stomp: number,
	tricks: { string },
	trickEvery: number,
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
	},
}

local Etapas = {}

-- La etapa sale del nombre del modelo (…E1 … E4); sin modelo, el becerro.
function Etapas.forModel(name: string?): Profile
	local stage = if name then tonumber(string.match(name, "E(%d)$")) else nil
	return PROFILES[math.clamp(stage or 1, 1, #PROFILES)]
end

return table.freeze(Etapas)
