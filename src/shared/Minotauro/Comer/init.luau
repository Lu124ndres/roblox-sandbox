--!strict
--[[
	Minotauro/Comer

	La reacción del minotauro a cada pez que le llega (solo en este cliente,
	con os.clock: cada cliente recibe los mismos peces casi a la vez). Se suma a
	lo que ya hace al comer (Pose.feeding) y le quita a esa pose lo que pida la
	reacción (takes: con los brazos ocupados deja de estirarlos):
		- cada pez: traga con un cabeceo chico y sacude una oreja (de a una);
		- un bocado (Comer/Bocados) cada tanto, no uno por pez: el siguiente
		  empieza cuando el anterior va por el 75 % y alterna variantes
		  (Comer/Elegir); la anterior se suelta suave (Comer/Mezcla);
		- un pez raro (rarity >= 3) gana a los bocados: Comer/Gustos, más grande
		  cuanto más raro, con sus ojos brillando del color de la rareza;
		- los combos (5, 15, 30 peces seguidos y cada 25 después) ganan a todo
		  (como todo, esperan a que termine el gesto que está haciendo):
		  Comer/Festejos, con PARTY_GAP segundos de espera entre uno y otro (si
		  llega a otro combo mientras espera, lo festeja al terminar la espera
		  si todavía le están dando de comer);
		- si el pez lo dio el jugador de este cliente, lo mira LOOK segundos
		  (cabeza y cuello) y cada WINK_EVERY segundos le guiña: ladea la
		  cabeza hacia él, le para una oreja y le hace un cabezazo (wink); esto
		  y lo de cada pez lo suma Comer/Acentos.
	Todos los tiempos se multiplican por el pace de la etapa (la forma final es
	más lenta) y en las etapas que no saltan (Etapas.tricks sin "salto") los
	saltitos se hacen en el lugar. Los eventos van a `out` como los de los trucos;
	glow lleva la rareza ("glow3" .. "glow6") para el color del brillo.
	step recibe cuánto puede reaccionar (weight: menos caminando, nada enojado o
	evolucionando: entonces suelta todo) y devuelve la pose y el takes.
]]

local Etapas = require(script.Parent.Etapas)
local Pose = require(script.Parent.Pose)
local Acentos = require(script.Acentos)
local Elegir = require(script.Elegir)
local Mezcla = require(script.Mezcla)
local Tipos = require(script.Tipos)

export type Fed = Tipos.Fed

local PARTY_GAP = 4 -- s de espera después de un festejo (deja ver los bocados)
local STALE = 1.5 -- s sin peces: ya no festeja el combo que esperaba
local LOOK = 1.6 -- s que mira al jugador local después de su pez
local WINK_EVERY = 5 -- s como mínimo entre guiños
local WINK = 0.8 -- s que dura el guiño
local INBOX = 16 -- peces que guarda entre un cuadro y el siguiente

export type Comer = {
	inbox: { Fed },
	playing: { Mezcla.Playing },
	turn: number,
	streak: number,
	reached: number,
	done: number,
	nextParty: number,
	rare: Fed?,
	bite: Fed?,
	look: Acentos.State,
	nextWink: number,
}
type Ctx = { profile: Etapas.Profile, pivot: CFrame, height: number, weight: number }

local Comer = {}

function Comer.new(): Comer
	return {
		inbox = {},
		playing = {},
		turn = 0,
		streak = 0,
		reached = 0,
		done = 0,
		nextParty = 0,
		rare = nil,
		bite = nil,
		look = Acentos.new(),
		nextWink = 0,
	}
end

function Comer.fed(c: Comer, info: Fed)
	if #c.inbox < INBOX then
		table.insert(c.inbox, info)
	end
end

-- Desde dónde vino respecto de adonde mira (rad, + a su izquierda).
local function angleTo(pivot: CFrame, point: Vector3): number
	local v = pivot:PointToObjectSpace(point)
	return math.atan2(-v.X, -v.Z)
end

local function take(c: Comer, info: Fed, now: number, ctx: Ctx, out: { { kind: string } })
	local pace, look = ctx.profile.pace, c.look
	look.fish += 1
	look.lastFish = now
	if info.streak < c.streak then -- empezó otra racha
		c.reached, c.done = 0, 0
	end
	c.streak = info.streak
	c.reached = Elegir.milestone(info.streak)
	local rare = c.rare
	if info.rarity >= Elegir.RARE then
		if not rare or info.rarity > rare.rarity then
			c.rare = info
		end
	else
		c.bite = info
	end
	if info.isLocal then
		if not look.lookAt or now > look.lookUntil then
			look.lookFrom = now
		end
		look.lookAt, look.lookUntil = info.from, now + LOOK * pace
		if now >= c.nextWink then
			look.winkAt, c.nextWink = now, now + WINK_EVERY
			look.winkSide = Elegir.side(angleTo(ctx.pivot, info.from), look.fish)
			table.insert(out, { kind = "wink" })
		end
	end
end

local function schedule(c: Comer, now: number, ctx: Ctx)
	local pace = ctx.profile.pace
	local prio, free = Mezcla.lead(c.playing, now)
	local rare, bite = c.rare, c.bite
	c.bite = nil -- un bocado que no entra ya no se hace: vendrán más peces
	local eating = now - c.look.lastFish < STALE
	local partyReady = c.reached > c.done and now >= c.nextParty and eating
	if not free then -- la que está deja terminar su gesto (y sus sonidos)
		return
	elseif partyReady then
		local move = Elegir.party(c.reached)
		c.done, c.rare = c.reached, nil
		c.nextParty = now + move.seconds * pace + PARTY_GAP
		Mezcla.start(c.playing, move, 1, now, pace)
	elseif rare then
		c.rare = nil
		local side = Elegir.side(angleTo(ctx.pivot, rare.from), c.look.fish)
		Mezcla.start(c.playing, Elegir.rare(rare.rarity), side, now, pace, rare.rarity)
	elseif bite and prio <= 1 then
		c.turn += 1
		local angle = angleTo(ctx.pivot, bite.from)
		local move = Elegir.bite(c.turn, angle)
		Mezcla.start(c.playing, move, Elegir.side(angle, c.turn), now, pace)
	end
end

-- pivot: dónde está y adonde mira; weight: cuánto puede reaccionar (0..1).
function Comer.step(
	c: Comer,
	profile: Etapas.Profile,
	pivot: CFrame,
	height: number,
	weight: number,
	out: { { kind: string } }
): (Pose.Pose, number)
	local now = os.clock()
	local ctx: Ctx = { profile = profile, pivot = pivot, height = height, weight = weight }
	if ctx.weight < 0.02 then -- evoluciona o está enojado: suelta todo
		table.clear(c.inbox)
		table.clear(c.playing)
		c.rare, c.bite, c.look.winkAt = nil, nil, nil
		return {}, 0
	end
	for _, info in c.inbox do
		take(c, info, now, ctx, out)
	end
	table.clear(c.inbox)
	schedule(c, now, ctx)

	local pace = ctx.profile.pace
	local hop = if table.find(ctx.profile.tricks, "salto") then 1 / pace else 0
	local playing, pose, takes = Mezcla.mix(c.playing, now, pace, { hop = hop }, out)
	c.playing = playing
	Acentos.add(c.look, pose, now, pace, ctx.pivot, ctx.height, WINK * pace)
	local final: Pose.Pose = {}
	Pose.add(final, pose, ctx.weight)
	return final, takes * ctx.weight
end

return table.freeze(Comer)
