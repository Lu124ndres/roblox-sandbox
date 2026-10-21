--!strict
--[[
	OrcaMotion/Comer/Estilo

	Cómo pide y come la comida cada etapa de la orca (el nombre del perfil de
	Etapas). Cuanto más grande, más pesada y lenta: tarda más en salir, aletea
	más despacio para sostenerse, abre la boca antes y traga más largo.
		- la cría es impaciente: da saltitos en el lugar y abre y cierra rápido;
		- la anciana sale menos vertical (pesa demasiado), abre una boca
		  enorme y traga pesado.
	Alturas en altos del modelo (negativo = bajo el agua), ángulos en
	radianes, tiempos en segundos. La boca va de 0 (cerrada) a 1.2.
]]

export type Estilo = {
	outDepth: number, -- centro del cuerpo asomada: las pectorales quedan a ras del agua
	outPitch: number, -- casi vertical, como al espiar (spyhop)
	lean: number, -- se inclina hacia quien la alimenta cuando viene un pez
	rise: number, -- s que tarda en salir
	sink: number, -- s que tarda en hundirse hacia atrás al irse
	wait: number, -- s que espera afuera, mirando, cuando dejan de tirarle
	kick: number, -- aletazos por segundo que la sostienen afuera
	bob: number, -- cuánto sube con cada aletazo
	open: number, -- boca abierta al pedir el pez
	lead: number, -- s antes de que llegue el pez en que empieza a abrir
	bite: number, -- s que dura el mordisco (cierra y golpea con la cabeza)
	swallow: number, -- s que traga con la boca cerrada
	chew: number, -- mordiscos por segundo al masticar entre bocados
	hop: number, -- saltitos de impaciencia (0 = no salta)
	hopRate: number, -- saltitos por segundo
}

local ADULTA: Estilo = {
	outDepth = -0.36,
	outPitch = 1.2,
	lean = 0.22,
	rise = 1.5,
	sink = 2,
	wait = 2,
	kick = 0.9,
	bob = 0.022,
	open = 1.1,
	lead = 0.5,
	bite = 0.12,
	swallow = 0.28,
	chew = 2.2,
	hop = 0,
	hopRate = 0,
}

local BY_NAME: { [string]: Estilo } = {
	OrcaBebe = {
		outDepth = -0.3,
		outPitch = 1.3,
		lean = 0.15,
		rise = 0.8,
		sink = 1.2,
		wait = 1.1,
		kick = 1.7,
		bob = 0.035,
		open = 0.95,
		lead = 0.35,
		bite = 0.08,
		swallow = 0.14,
		chew = 4.5,
		hop = 0.1,
		hopRate = 1.4,
	},
	OrcaJoven = {
		outDepth = -0.33,
		outPitch = 1.25,
		lean = 0.2,
		rise = 1.1,
		sink = 1.5,
		wait = 1.5,
		kick = 1.25,
		bob = 0.028,
		open = 1,
		lead = 0.42,
		bite = 0.1,
		swallow = 0.2,
		chew = 3,
		hop = 0,
		hopRate = 0,
	},
	OrcaAdulta = ADULTA,
	OrcaAnciana = {
		outDepth = -0.42,
		outPitch = 1,
		lean = 0.15,
		rise = 2.6,
		sink = 3,
		wait = 2.6,
		kick = 0.5,
		bob = 0.012,
		open = 1.2,
		lead = 0.7,
		bite = 0.15,
		swallow = 0.38,
		chew = 1.2,
		hop = 0,
		hopRate = 0,
	},
}

local Estilo = {}

-- El estilo de la etapa (la Orca fantasma usa los mismos nombres de etapa).
function Estilo.of(profileName: string): Estilo
	return BY_NAME[profileName] or ADULTA
end

return table.freeze(Estilo)
