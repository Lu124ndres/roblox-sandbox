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
		tricks     los trucos que hace (Minotauro/Trucos) cuando su rutina pide "truco"
		pace       cuánto más lentos son sus trucos, sus posturas y sus resortes (1 = becerro)
		bounce     amortiguación de los resortes (Minotauro/Resortes): baja rebota,
		           alta se queda quieta enseguida
		rutina     lo que hace cuando nadie le da de comer y paso, su manera de
		paso       caminar (Minotauro/Habitos)
		body       medidas del cuerpo (Minotauro/Medidas)
]]

local Habitos = require(script.Parent.Habitos)
local Medidas = require(script.Parent.Medidas)

export type Body = Medidas.Body
export type Rutina = Habitos.Rutina
export type Paso = Habitos.Paso

export type Profile = {
	breathe: number,
	tail: number,
	turnSpeed: number,
	sway: number,
	voice: number,
	stomp: number,
	tricks: { string },
	pace: number,
	bounce: number,
	rutina: Rutina,
	paso: Paso,
	body: Body,
}

local PROFILES: { [number]: Profile } = {
	{ -- becerro: inquieto y juguetón; trota, cambia seguido de lugar y de idea
		breathe = 2.6,
		tail = 1.8,
		turnSpeed = 1.3,
		sway = 1.2,
		voice = 1.35,
		stomp = 0.7,
		tricks = { "baile", "salto", "pisoton", "rugido", "baile", "musculo", "salto", "rascarse" },
		pace = 1,
		bounce = 0.28,
		rutina = Habitos.rutinas[1],
		paso = Habitos.pasos[1],
		body = Medidas[1],
	},
	{ -- joven: fanfarrón; camina sacando pecho, se luce y mira a la gente
		breathe = 3,
		tail = 2.1,
		turnSpeed = 1.15,
		sway = 1,
		voice = 1.1,
		stomp = 0.9,
		tricks = { "pisoton", "musculo", "baile", "rugido", "salto", "rascarse" },
		pace = 1.1,
		bounce = 0.38,
		rutina = Habitos.rutinas[2],
		paso = Habitos.pasos[2],
		body = Medidas[2],
	},
	{ -- adulto: pesado; pasea agachado, se sienta y a veces dormita
		breathe = 3.5,
		tail = 2.5,
		turnSpeed = 0.95,
		sway = 0.85,
		voice = 0.88,
		stomp = 1.15,
		tricks = { "pisoton", "rugido", "musculo", "salto", "pisoton", "rascarse" },
		pace = 1.25,
		bounce = 0.5,
		rutina = Habitos.rutinas[3],
		paso = Habitos.pasos[3],
		body = Medidas[3],
	},
	{ -- forma final: enorme y lento; camina poco, se sienta pesado y dormita
		breathe = 4.2,
		tail = 3,
		turnSpeed = 0.75,
		sway = 0.7,
		voice = 0.7,
		stomp = 1.5,
		tricks = { "rugido", "pisoton", "musculo", "pisoton", "rugido", "rascarse" },
		pace = 1.45,
		bounce = 0.65,
		rutina = Habitos.rutinas[4],
		paso = Habitos.pasos[4],
		body = Medidas[4],
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
