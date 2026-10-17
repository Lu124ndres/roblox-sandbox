--!strict
--[[
	Dragon/Estadia

	Lo que hace el dragón mientras está posado:
		schedule(stay, now, profile)  qué postura toca a esa hora (igual en todos los
		        clientes): primero posarse (el asiento al tocar la roca), después las
		        de rutina.list elegidas con Azar(vuelta, i), con rutina.gap entre una y
		        otra; si la siguiente no entra, se queda de pie mirando alrededor. Si
		        esa vez duerme, el final de la estadía (60 %, al menos 14 s por el
		        pace) es dormir. Devuelve la postura, su avance y su Ctx (o nil).
		play(player, ...)  la pone sobre la pose de estar posado (Posturas.base):
		        manda sus eventos cuando el avance pasa por ellos (al entrar a la
		        mitad no repite los que ya pasaron) y evolucionando la apaga de a poco
		        (mute) sin sonar nada
		fade(player, dt)  si la cortan (despega para comer), lo que quedaba de la
		        postura se desvanece en FADE s en vez de saltar
]]

local Azar = require(script.Parent.Parent.Minotauro.Azar)
local C = require(script.Parent.Parent.Minotauro.Trucos.Curvas)
local Etapas = require(script.Parent.Etapas)
local Pose = require(script.Parent.Pose)
local Posturas = require(script.Parent.Posturas)

local FADE = 0.35
local MAX_STAY = 12 -- posturas por estadía (para la semilla)
local SLEEP = { share = 0.6, least = 14 }

export type Stay = { cycle: number, landAt: number, takeoffAt: number, sleeps: boolean }
export type Player = { key: number, lastU: number, mute: number, last: Pose.Pose?, fadeW: number }

local Estadia = {}

function Estadia.schedule(
	stay: Stay,
	now: number,
	profile: Etapas.Profile
): (Posturas.Behavior?, number, Posturas.Ctx)
	local r, pace = profile.rutina, profile.pace
	local cursor = stay.landAt
	local found: Posturas.Behavior?, u, ctx = nil, 0, { profile = profile, seed = 0, seconds = 1 }
	local function try(behavior: Posturas.Behavior, seconds: number, seed: number): boolean
		if now >= cursor and now < cursor + seconds then
			found, u = behavior, (now - cursor) / seconds
			ctx = { profile = profile, seed = seed, seconds = seconds }
			return true
		end
		cursor += seconds + r.gap
		return false
	end
	local settle = Posturas.get("posarse") :: Posturas.Behavior
	if try(settle, settle.seconds * pace, stay.cycle * MAX_STAY) then
		return found, u, ctx
	end
	local sleepFor = if stay.sleeps
		then math.max((stay.takeoffAt - cursor) * SLEEP.share, SLEEP.least * pace)
		else 0
	local awake = stay.takeoffAt - sleepFor
	for i = 1, MAX_STAY - 2 do
		local behavior = Posturas.get(r.list[Azar.pick(#r.list, stay.cycle, 10 + i)])
		local seconds = if behavior then behavior.seconds * pace else 0
		if not behavior or cursor + seconds > awake then
			break
		end
		if try(behavior, seconds, stay.cycle * MAX_STAY + i) then
			return found, u, ctx
		end
	end
	if stay.sleeps and now >= awake then
		cursor = awake
		try(
			Posturas.get("dormir") :: Posturas.Behavior,
			stay.takeoffAt - awake,
			stay.cycle * MAX_STAY + MAX_STAY - 1
		)
	end
	return found, u, ctx
end

function Estadia.newPlayer(): Player
	return { key = -1, lastU = 0, mute = 0, last = nil, fadeW = 0 }
end

function Estadia.play(
	k: Player,
	b: Posturas.Behavior?,
	u: number,
	ctx: Posturas.Ctx,
	now: number,
	dt: number,
	evolving: boolean,
	fresh: boolean,
	out: { { kind: string } }
): Pose.Pose
	local pose = Posturas.base(now, 3 * ctx.profile.pace)
	k.mute += ((if evolving then 1 else 0) - k.mute) * math.min(1, dt * 6)
	if not b then
		k.last = nil
		return pose
	end
	if ctx.seed ~= k.key then
		k.key, k.lastU = ctx.seed, if fresh then u else -1
	end
	if not evolving then
		for _, event in b.events(ctx) do
			if event.at > k.lastU and event.at <= u then
				table.insert(out, { kind = event.kind })
			end
		end
	end
	k.lastU = u
	local posture = b.pose(u, ctx)
	Pose.add(pose, posture, 1 - k.mute)
	k.last, k.fadeW = posture, 1 - k.mute
	return pose
end

function Estadia.fade(k: Player, dt: number): Pose.Pose
	local pose: Pose.Pose = {}
	local last = k.last
	if last then
		k.fadeW = math.max(0, k.fadeW - dt / FADE)
		Pose.add(pose, last, C.smooth(k.fadeW))
		if k.fadeW <= 0 then
			k.last = nil
		end
	end
	return pose
end

return table.freeze(Estadia)
