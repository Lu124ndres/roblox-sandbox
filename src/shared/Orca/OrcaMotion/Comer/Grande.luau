--!strict
--[[
	OrcaMotion/Comer/Grande

	Corre la reacción grande de la orca al comer (salto por un pez raro o
	festejo de combo, de Festejos): pide a Turnos la que toca, la avanza,
	dispara sus momentos una sola vez y da su pose con cuánto manda (entra y
	sale suave en BLEND, como los trucos de Schedule). Los trucos de siempre
	arrancan nadando derecha: al empezar y al terminar se les suma el
	cabeceo de la orca asomada (CARRY), así no se acuesta para volver a
	pararse.
]]

local WorldLayout = require(script.Parent.Parent.Parent.Parent.WorldLayout)
local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Schedule = require(script.Parent.Parent.Schedule)
local Tricks = require(script.Parent.Parent.Tricks)
local Festejos = require(script.Parent.Festejos)
local Turnos = require(script.Parent.Turnos)

local smooth, span = Tricks.smooth, Tricks.span

local BLEND = 0.12 -- parte de la reacción que se usa para entrar y salir
local CARRY = 0.3 -- parte del principio y del final en que conserva el cabeceo asomada
local WATER = WorldLayout.waterLevel

export type Big = {
	trick: Tricks.Trick,
	t: number,
	from: number,
	progress: number,
	party: boolean,
	carry: boolean, -- arranca nadando: conserva el cabeceo asomada al entrar y salir
}
export type View = { center: Vector3, height: number }

local Grande = {}

-- Momentos de `list` entre el avance anterior y el actual (spot: de dónde vino el pez).
function Grande.fire(
	list: { Tricks.Event },
	before: number,
	now: number,
	events: { Schedule.Event },
	spot: Vector3?
)
	for _, event in list do
		if event.at > before and event.at <= now then
			table.insert(events, { kind = event.kind, where = event.where, spot = spot })
		end
	end
end

-- Empieza la que toca si no hay ninguna. Devuelve la reacción en curso (o nil).
function Grande.start(
	big: Big?,
	turnos: Turnos.Turnos,
	meal: Perfil.Meal,
	view: View,
	now: number
): Big?
	if big then
		return big
	end
	local trick, party = Turnos.nextBig(turnos, meal, now)
	if not trick then
		return nil
	end
	-- Arranca desde la altura en que está (comiendo, con la cabeza afuera).
	local from = (view.center.Y - WATER) / math.max(view.height, 1)
	local carry = not Festejos.upright(trick)
	return { trick = trick, t = 0, from = from, progress = 0, party = party, carry = carry }
end

-- Avanza la reacción: su pose, cuánto manda y qué parte del cabeceo de la
-- postura conserva (0..1); nil si terminó.
function Grande.step(
	big: Big,
	turnos: Turnos.Turnos,
	dt: number,
	now: number,
	events: { Schedule.Event }
): (Tricks.Pose?, number, number)
	big.t += dt
	local u = big.t / big.trick.seconds
	if u >= 1 then
		Turnos.endBig(turnos, now, big.party)
		return nil, 0, 0
	end
	Grande.fire(big.trick.events, big.progress, u, events, turnos.from)
	big.progress = u
	local weight = smooth(u / BLEND) * smooth((1 - u) / BLEND)
	local carry = 0
	if big.carry then
		carry = 1 - smooth(span(u, 0, CARRY)) + smooth(span(u, 1 - CARRY, 1))
	end
	return big.trick.pose(u, big.from), weight, carry
end

return table.freeze(Grande)
