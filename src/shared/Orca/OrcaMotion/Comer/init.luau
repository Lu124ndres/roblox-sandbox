--!strict
--[[
	OrcaMotion/Comer

	Cómo come la orca, como una orca de verdad que pide comida junto al borde.
	Cada cliente la arma con los mismos lotes de GiantFed (Feeders) y los
	mismos peces (FedInfo), así que todos la ven casi igual:
		1. llega: deja lo que hacía y nada a la orilla del que le toca
		   (Feeders atiende de a uno, en orden);
		2. sale: se asoma casi vertical, mirándolo (Postura);
		3. abre la boca antes de cada pez y la cabeza sigue el bocado; al
		   llegar muerde, traga y vuelve a abrir; en racha mastica entre
		   bocados (Boca);
		4. reacciona: un pez raro da sorpresa y después un salto chico al
		   lado, un giro de costado o un aletazo; las rachas, festejos cada
		   vez más grandes (Turnos, Festejos, Grande); entre peces, gestos de
		   gusto que crecen con la racha (Gestos, Mezcla);
		5. cuando no le tiran más espera mirando (y vuelve a pedir si el
		   jugador sigue ahí), se hunde hacia atrás y vuelve al recorrido.
	Cada etapa a su manera (Estilo): la cría, impaciente; la anciana, pesada.
	La postura y las reacciones grandes mandan como un truco con el peso de
	comer; los gestos se suman por resortes y la boca, directo.
]]

local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Feeders = require(script.Parent.Feeders)
local Schedule = require(script.Parent.Schedule)
local Tricks = require(script.Parent.Tricks)
local Boca = require(script.Boca)
local Estilo = require(script.Estilo)
local Gestos = require(script.Gestos)
local Grande = require(script.Grande)
local Mezcla = require(script.Mezcla)
local Postura = require(script.Postura)
local Turnos = require(script.Turnos)

local QUIET = 1 -- s sin lotes (o sin peces): ya no vienen más
local NEXT_FREE = 0.9 -- s: si el próximo pez llega antes, no se distrae con gestos
local FULL_AT = 0.5 -- con este interés (state.feeding) la comida ya manda del todo
local LOOK_SWIMMING = 0.3 -- nadando gira para mirar solo esta parte (no nada de costado)

export type Add = Gestos.Add
export type Info = Turnos.Info
export type Pose = Postura.Pose
export type Out = { pose: Pose?, weight: number, yaw: number, add: Add }
-- Lo que ve de la orca (OrcaMotion.State).
export type View = { center: Vector3, yaw: number, height: number, speed: number, feeding: number }
export type Comer = {
	feeders: Feeders.Feeders?,
	turnos: Turnos.Turnos,
	postura: Postura.Postura,
	boca: Boca.Boca,
	mezcla: Mezcla.Mezcla,
	big: Grande.Big?,
	calmAt: number, -- os.clock en que terminó la última reacción grande
	lastAt: number, -- el último lote del que atiende
}

local Comer = {}
Comer.zero = table.freeze(Gestos.zero()) -- sin gestos

-- feeders: los de OrcaMotion (por turnos); sin ellos se guía por el ritmo de los peces.
function Comer.new(feeders: Feeders.Feeders?): Comer
	return {
		feeders = feeders,
		turnos = Turnos.new(),
		postura = Postura.new(),
		boca = Boca.new(),
		mezcla = Mezcla.new(),
		calmAt = -math.huge,
		lastAt = -math.huge,
	}
end

-- Llegó un pez a la boca: muerde (y se sorprende si es raro).
function Comer.fed(comer: Comer, info: Info, profile: Perfil.Profile, events: { Schedule.Event })
	local now = os.clock()
	local power = Turnos.fed(comer.turnos, info, now)
	Boca.bite(comer.boca, now)
	table.insert(events, { kind = "snap", size = info.rarity })
	if power > 0 then
		table.insert(events, { kind = "shine", size = power })
		Mezcla.start(comer.mezcla, "sorpresa", profile.meal.tempo, false)
	end
end

-- Qué está haciendo: comiendo (o llegando), esperando más o yéndose.
local function moment(
	comer: Comer,
	style: Estilo.Estilo,
	feeding: number,
	a: number,
	now: number
): (Boca.Mode, Feeders.Target?)
	local feeders = comer.feeders
	local target = if feeders then feeders.target() else nil
	comer.lastAt = if target then target.lastAt else comer.lastAt
	-- Después de una reacción grande vuelve a esperar desde el principio.
	local last = math.max(if target then target.lastAt else comer.boca.lastFed, comer.calmAt)
	local quiet = if last == -math.huge then 0 else now - last -- aún sin peces: va llegando
	-- Sin Feeders, que se apague el interés solo cuenta si ya comió algo.
	local fading = not feeders and feeding < 0.3 and last ~= -math.huge
	if (feeders and not target) or fading or quiet > QUIET + style.wait then
		return "leave", target
	end
	return if quiet > QUIET and a <= 0 then "wait" else "eat", target
end

-- close: qué tan cerca está de la orilla de quien la alimenta (Steer.follow, 0..1).
function Comer.step(
	comer: Comer,
	dt: number,
	profile: Perfil.Profile,
	view: View,
	events: { Schedule.Event },
	close: number?
): Out
	local now = os.clock()
	local turnos, meal, boca = comer.turnos, profile.meal, comer.boca
	local style = Estilo.of(profile.name)
	local feeders = comer.feeders
	if feeders then
		-- Espera, se hunde y recién se va (más tarde si festejó después del último pez).
		local late = math.max(0, comer.calmAt - comer.lastAt)
		feeders.linger = style.wait + style.sink + late
	end
	local ex = Boca.expect(boca, style, if feeders then feeders.incoming else nil, now)
	local mode, target = moment(comer, style, view.feeding, ex.a, now)
	local swallowing = now - boca.bitAt < style.bite + style.swallow
	local pose, extra = Postura.step(comer.postura, style, profile.swim, dt, now, view, {
		close = close or view.feeding,
		engaged = view.feeding > 0.3,
		leaving = mode == "leave",
		expect = ex.a,
		eager = mode ~= "leave" and not swallowing,
	}, events)

	-- Reacción grande (pez raro o festejo): manda sobre la postura con su peso.
	comer.big = Grande.start(comer.big, turnos, meal, view, now)
	local big: Tricks.Pose, bw, carry = {}, 0, 0
	if comer.big then
		comer.calmAt = now
		local p, w, c = Grande.step(comer.big, turnos, dt, now, events)
		big, bw, carry = p or {}, w, c
		comer.big = if p then comer.big else nil
	end
	Mezcla.over(pose, big, bw, carry)
	local free = mode ~= "eat" or (not swallowing and (ex.tau == nil or ex.tau > NEXT_FREE))
	Mezcla.choose(comer.mezcla, turnos, meal, now, free, comer.big ~= nil, events)
	local add = Mezcla.step(comer.mezcla, turnos, meal, dt, now, bw, events)

	-- Boca y cabeza pez por pez, y los aletazos que la sostienen (directo: ya son suaves).
	local lookAt = Turnos.localFeeder(turnos, now)
		or (if target then target.position else turnos.from)
	local present = target == nil or target.present
	local mouth =
		Boca.step(boca, style, meal.snap, dt, now, view, ex, mode, pose.pitch or 0, lookAt, present)
	local keep = 1 - bw
	pose.jaw = mouth.jaw + ((big.jaw or mouth.jaw) - mouth.jaw) * bw
	add.head += mouth.head * keep
	add.pitch += mouth.pitch * keep
	add.depth += (mouth.depth + extra.lift) * keep
	local out = math.clamp(comer.postura.out.x, 0, 1)
	add.yaw += mouth.yaw * keep * (LOOK_SWIMMING + (1 - LOOK_SWIMMING) * out)
	add.fins += mouth.fins * keep
	add.waveIzq += extra.scull * keep
	add.waveDer -= extra.scull * keep
	local weight = Tricks.smooth(view.feeding / FULL_AT) -- antes de que Body abra su boca de comer
	weight += (1 - weight) * bw
	return {
		pose = pose,
		weight = weight,
		yaw = pose.yaw or 0, -- ya va con el peso de la reacción
		add = add,
	}
end

return table.freeze(Comer)
