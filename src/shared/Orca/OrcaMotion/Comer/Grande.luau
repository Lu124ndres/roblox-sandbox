--!strict
--[[
	OrcaMotion/Comer/Grande

	Corre la reacción grande de la orca al comer (salto por un pez raro o
	festejo de combo, de Festejos): pide a Turnos la que toca, la avanza,
	dispara sus momentos una sola vez y da su pose con cuánto manda (entra y
	sale suave en BLEND, como los trucos de Schedule).
]]

local WorldLayout = require(script.Parent.Parent.Parent.Parent.WorldLayout)
local Perfil = require(script.Parent.Parent.Parent.Etapas.Perfil)
local Schedule = require(script.Parent.Parent.Schedule)
local Tricks = require(script.Parent.Parent.Tricks)
local Turnos = require(script.Parent.Turnos)

local BLEND = 0.12 -- parte de la reacción que se usa para entrar y salir
local WATER = WorldLayout.waterLevel

export type Big = { trick: Tricks.Trick, t: number, from: number, progress: number, party: boolean }
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
	return { trick = trick, t = 0, from = from, progress = 0, party = party }
end

-- Avanza la reacción: su pose y cuánto manda, o nil si terminó.
function Grande.step(
	big: Big,
	turnos: Turnos.Turnos,
	dt: number,
	now: number,
	events: { Schedule.Event }
): (Tricks.Pose?, number)
	big.t += dt
	local u = big.t / big.trick.seconds
	if u >= 1 then
		Turnos.endBig(turnos, now, big.party)
		return nil, 0
	end
	Grande.fire(big.trick.events, big.progress, u, events, turnos.from)
	big.progress = u
	return big.trick.pose(u, big.from), Tricks.smooth(u / BLEND) * Tricks.smooth((1 - u) / BLEND)
end

return table.freeze(Grande)
