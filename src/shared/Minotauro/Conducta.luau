--!strict
--[[
	Minotauro/Conducta

	Lleva, en cada cliente, la postura de la rutina que está haciendo
	(Minotauro/Rutina dice cuál toca; esto decide si la hace):
		- una postura empieza solo si al empezar ya llegó a su lugar y no está
		  girando (ready), o si el cliente recién lo ve (fresh: entra a la mitad,
		  como los demás); si llega tarde, se la salta y espera la siguiente;
		- si deja de estar libre (le dan de comer, evoluciona, se enoja o se va),
		  sale con la salida de la postura (leave: sentado, se para) o se desvanece
		  en FADE segundos, y no la retoma;
		- los eventos de la postura (y de la salida) van a `out` cuando el avance
		  pasa por ellos; al entrar a la mitad no se repiten los que ya pasaron.
	step devuelve lo que se suma a la pose (o nil) y si está ocupado (quieto en su
	lugar: ni camina ni gira, salvo las posturas que miran a alguien).
]]

local C = require(script.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Pose)
local Posturas = require(script.Parent.Posturas)
local Rutina = require(script.Parent.Rutina)

local ENTRY = 0.6 -- s: si llega más tarde que esto al principio de una postura, la salta
local FADE = 0.5 -- s: salida si la postura no tiene una propia

export type Conducta = {
	playing: Posturas.Behavior?,
	key: number,
	lastU: number,
	ctx: Posturas.Ctx?,
	events: { Posturas.Event },
	skip: number,
	leave: Posturas.Leave?,
	leaveK: number,
	leaveSeconds: number,
	fresh: boolean,
}

local Conducta = {}

function Conducta.new(): Conducta
	return {
		playing = nil,
		key = 0,
		lastU = 0,
		ctx = nil,
		events = {},
		skip = 0,
		leave = nil,
		leaveK = 0,
		leaveSeconds = 1,
		fresh = true,
	}
end

local function emit(events: { Posturas.Event }, from: number, to: number, out: { { kind: string } })
	for _, event in events do
		if event.at > from and event.at <= to then
			table.insert(out, { kind = event.kind })
		end
	end
end

-- Se desvanece en FADE segundos sin dejar de moverse.
local function fadeOut(b: Posturas.Behavior, from: number, ctx: Posturas.Ctx): Posturas.Leave
	local seconds = b.seconds * ctx.profile.pace
	return {
		seconds = FADE / ctx.profile.pace, -- Conducta lo multiplica por el pace
		events = {},
		pose = function(k: number): Pose.Pose
			local out = {}
			Pose.add(out, b.pose(math.min(1, from + k * FADE / seconds), ctx), 1 - C.smooth(k))
			return out
		end,
	}
end

function Conducta.step(
	k: Conducta,
	plan: Rutina.Plan,
	dt: number,
	free: boolean,
	ready: boolean,
	out: { { kind: string } }
): (Pose.Pose?, boolean)
	local playing, ctx = k.playing, k.ctx
	if playing and ctx and (not free or plan.key ~= k.key) then
		k.playing = nil
		k.skip = k.key
		if k.lastU < 0.98 then -- la cortaron (o se corrió el horario al crecer): sale
			local leave = (playing.leave and playing.leave(k.lastU, ctx))
				or fadeOut(playing, k.lastU, ctx)
			k.leave, k.leaveK = leave, 0
			k.leaveSeconds = leave.seconds * ctx.profile.pace
		end
	end
	local leave = k.leave
	if leave then
		local before = k.leaveK
		k.leaveK = math.min(1, before + dt / k.leaveSeconds)
		emit(leave.events, before, k.leaveK, out)
		if k.leaveK >= 1 then
			k.leave = nil
		end
		return leave.pose(k.leaveK), true
	end
	local b = plan.behavior
	if not free or not b then
		k.fresh = false
		return nil, false
	end
	if not k.playing then
		if plan.key == k.skip then
			return nil, false
		elseif not (k.fresh or (ready and plan.elapsed < ENTRY)) then
			k.skip = plan.key -- llegó tarde: espera la siguiente
			return nil, false
		end
		k.playing, k.key, k.ctx = b, plan.key, plan.ctx
		k.events = b.events(plan.ctx)
		k.lastU = if k.fresh then plan.u else -1
	end
	k.fresh = false
	emit(k.events, k.lastU, plan.u, out)
	k.lastU = plan.u
	return b.pose(plan.u, k.ctx or plan.ctx), true
end

return table.freeze(Conducta)
