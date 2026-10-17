--!strict
--[[
	Dragon/Comer

	La animación especial al comer: lo que hace el dragón con cada pez que le
	llega a la boca (fed), encima de lo que ya hace al comer (va frente a quien
	lo alimenta y se queda en el aire con la boca abierta: Destino, Cuerpo).
	Capas (Comer/Capas) de actos (Comer/Acto) que se suman a la pose:
		bocado    cada pez (Comer/Bocados): arco, lado o cielo, alternando lados;
		          el nuevo funde al anterior y con peces muy seguidos (gap) se
		          achican (amp): se ven los comienzos, nunca un temblor
		trago     el bulto de cada pez bajando por el cuello (no se corta)
		golosina  un pez raro (Comer/Golosinas); festejo, las rachas (Festejos)
		saludo    al jugador de este cliente, cada GREET_EVERY s (Bocados.saludo)
	Golosinas, festejos y saludos no se cortan: uno nuevo espera a que termine
	(un pez raro que llega mientras tanto solo echa chispas: treat) y mientras
	tanto los bocados se achican. Mira a quien le dio (Comer/Mirar). Cada pez
	cierra la boca de golpe un rato (biting). Al evolucionar no empieza nada.
	Todo con os.clock: es local. Acto.offset corre el cuerpo (lunge, rise).
]]

local Azar = require(script.Parent.Parent.Minotauro.Azar)
local Etapas = require(script.Parent.Etapas)
local Tipos = require(script.Parent.Tipos)
local Acto = require(script.Acto)
local Bocados = require(script.Bocados)
local Capas = require(script.Capas)
local Festejos = require(script.Festejos)
local Golosinas = require(script.Golosinas)
local Mirar = require(script.Mirar)

local REST = 1 -- s de espera después de un festejo antes del siguiente
local GREET_EVERY = 4 -- s entre saludos al jugador de este cliente
local SKY_EVERY = 1.6 -- s entre bocados "cielo" (el aletazo cansa si es seguido)
local GULP_EVERY = 0.9 -- s entre tragos que suenan
local BITE_ORDER = { Bocados.arco, Bocados.lado, Bocados.cielo }

type Play = Capas.Play
type Pose = { [string]: number }
export type Comer = {
	bocado: { Play },
	golosina: { Play },
	festejo: { Play },
	saludo: { Play },
	trago: { Play },
	queue: { Tipos.Fed },
	lastFed: number,
	count: number,
	side: number,
	skyAt: number,
	gulpAt: number,
	due: number?, -- nivel de festejo ganado que espera su turno
	freeAt: number, -- desde cuándo puede festejar otra vez
	greetAt: number,
	shutUntil: number,
	from: Vector3?,
	fromAt: number,
	fromLocal: boolean,
}
type Situation = {
	now: number, -- os.clock()
	L: number,
	stage: number,
	profile: Etapas.Profile,
	yaw: number,
	center: Vector3,
	evolving: boolean,
	events: { Tipos.Event },
}

local Comer = {}

function Comer.new(): Comer
	return {
		bocado = {},
		golosina = {},
		festejo = {},
		saludo = {},
		trago = {},
		queue = {},
		lastFed = -math.huge,
		count = 0,
		side = 1,
		skyAt = -math.huge,
		gulpAt = -math.huge,
		freeAt = 0,
		greetAt = -math.huge,
		shutUntil = 0,
		fromAt = -math.huge,
		fromLocal = false,
	}
end

-- Le llegó un pez: se procesa en el próximo step (ahí sabe su etapa y su largo).
function Comer.fed(c: Comer, info: Tipos.Fed)
	table.insert(c.queue, info)
end

function Comer.biting(c: Comer, now: number): boolean
	return now < c.shutUntil
end

local function start(list: { Play }, act: Acto.Act, s: Situation, side: number, amp: number)
	local ctx = { L = s.L, stage = s.stage, profile = s.profile, side = side, amp = amp }
	Capas.start(list, act, s.now, ctx, s.profile.pace)
end

-- El festejo ganado o la golosina de este pez, si no hay otro sonando. true si empezó uno.
local function celebrate(c: Comer, info: Tipos.Fed, s: Situation): boolean
	local level = Festejos.level(info.streak)
	if info.streak <= 1 then
		c.due = nil
	elseif level then
		c.due = math.max(c.due or 0, level)
	end
	local treat = Golosinas.forRarity(info.rarity)
	local due = c.due
	if #c.festejo > 0 or #c.golosina > 0 then
		if treat then
			table.insert(s.events, { kind = "treat" }) -- ocupado: solo las chispas
		end
		return false
	elseif due and s.now >= c.freeAt then
		local act = Festejos.act(due)
		start(c.festejo, act, s, c.side, 1)
		c.due, c.freeAt = nil, s.now + act.seconds * s.profile.pace + REST
		return true
	elseif treat then
		start(c.golosina, treat, s, c.side, 1)
		return true
	end
	return false
end

local function take(c: Comer, info: Tipos.Fed, s: Situation)
	local now = s.now
	local gap = math.clamp(now - c.lastFed, 0.15, 2)
	c.lastFed, c.count, c.side = now, c.count + 1, -c.side
	c.from, c.fromAt, c.fromLocal = info.from, now, info.isLocal
	if Capas.busy({ c.festejo, c.golosina }, now) < 0.5 then -- rugiendo no cierra la boca
		c.shutUntil = now + math.clamp(0.3 * s.profile.pace, 0.12, gap * 0.55)
	end
	if s.evolving then
		return
	end
	local big = celebrate(c, info, s) or #c.festejo > 0 or #c.golosina > 0
	Capas.fade(c.bocado, now)
	local pick = BITE_ORDER[Azar.pick(#BITE_ORDER, c.count, 31)]
	if pick == Bocados.cielo and (now - c.skyAt < SKY_EVERY or big) then
		pick = if c.count % 2 == 0 then Bocados.arco else Bocados.lado
	elseif pick == Bocados.cielo then
		c.skyAt = now
	end
	local amp = 1 - 0.35 * (1 - math.clamp((gap - 0.45) / 1, 0, 1))
	start(c.bocado, pick, s, c.side, amp)
	local loud = now - c.gulpAt > GULP_EVERY
	c.gulpAt = if loud then now else c.gulpAt
	start(c.trago, if loud then Bocados.trago else Bocados.tragoQuieto, s, c.side, amp * 0.8)
	if info.isLocal and not big and #c.saludo == 0 and now - c.greetAt > GREET_EVERY then
		c.greetAt = now
		local rel = Mirar.bearing(info.from, s.center, s.yaw)
		start(c.saludo, Bocados.saludo, s, if rel >= 0 then 1 else -1, 1)
	end
end

-- La pose de comer de este cuadro (se suma a la del dragón); sus eventos van a state.events.
function Comer.step(
	c: Comer,
	state: Tipos.State,
	profile: Etapas.Profile,
	stage: number,
	yaw: number,
	evolving: boolean
): Pose
	local s: Situation = {
		now = os.clock(),
		L = state.length,
		stage = stage,
		profile = profile,
		yaw = yaw,
		center = state.center,
		evolving = evolving,
		events = state.events,
	}
	for _, info in c.queue do
		take(c, info, s)
	end
	table.clear(c.queue)
	local out: Pose = {}
	local quiet = 1 - 0.6 * Capas.busy({ c.festejo, c.golosina }, s.now)
	Capas.run(c.festejo, s.now, out, 1, s.events)
	Capas.run(c.golosina, s.now, out, 1, s.events)
	Capas.run(c.saludo, s.now, out, 1, s.events)
	Capas.run(c.bocado, s.now, out, quiet, s.events)
	Capas.run(c.trago, s.now, out, 1, s.events)
	Mirar.add(out, c.from, s.now - c.fromAt, c.fromLocal, s.center, s.yaw)
	return out
end

return table.freeze(Comer)
