--!strict
--[[
	ReelFight

	La cuenta del minijuego de recoger (Config.Reel), sin remotes ni
	atributos: FishingService la usa. La barra baja sola con el tiempo
	(`drain`) y sube con cada toque (`gain` x fuerza). Los toques pasan por
	un balde de fichas: como mucho maxTapsPerSecond, con tapBurst de
	colchón para los que llegan juntos por el ping.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Reel = require(ReplicatedStorage.Shared.Config.Reel)

export type Fight = {
	progress: number,
	gain: number,
	drain: number,
	startedAt: number,
	updatedAt: number, -- la barra baja desde aquí (empieza tras graceSeconds)
	tokens: number,
	tokensAt: number,
}

export type Params = { start: number, gain: number, drain: number, timeout: number }

local ReelFight = {}

-- Fuerza de los toques: la caña y los pases con traje la suben.
function ReelFight.strength(rodLevel: number, passStrength: number): number
	return (1 + Reel.strengthPerRodLevel * (rodLevel - 1)) * passStrength
end

function ReelFight.new(rarityIndex: number, strength: number, instant: boolean, now: number): Fight
	local tuning = Reel.byRarity[math.clamp(rarityIndex, 1, #Reel.byRarity)]
	return {
		progress = Reel.startProgress,
		gain = if instant then 1 else tuning.gain * strength,
		drain = tuning.drain,
		startedAt = now,
		updatedAt = now + Reel.graceSeconds,
		tokens = Reel.tapBurst,
		tokensAt = now,
	}
end

-- Lo que el cliente necesita para dibujar la barra igual que el servidor.
function ReelFight.params(fight: Fight): Params
	return {
		start = fight.progress,
		gain = fight.gain,
		drain = fight.drain,
		timeout = Reel.timeoutSeconds,
	}
end

-- Baja la barra hasta `now`. Devuelve "escaped" si se vació o se acabó el tiempo.
function ReelFight.update(fight: Fight, now: number): "escaped"?
	if now > fight.updatedAt then
		fight.progress -= fight.drain * (now - fight.updatedAt)
		fight.updatedAt = now
	end
	if fight.progress <= 0 or now - fight.startedAt > Reel.timeoutSeconds + Reel.graceSeconds then
		return "escaped"
	end
	return nil
end

-- Un toque. Devuelve "caught" al llenar la barra, "escaped" si ya se había ido.
function ReelFight.tap(fight: Fight, now: number): ("caught" | "escaped")?
	if ReelFight.update(fight, now) then
		return "escaped"
	end
	fight.tokens =
		math.min(Reel.tapBurst, fight.tokens + (now - fight.tokensAt) * Reel.maxTapsPerSecond)
	fight.tokensAt = now
	if fight.tokens < 1 then
		return nil -- demasiado rápido: el toque no cuenta
	end
	fight.tokens -= 1
	fight.progress += fight.gain
	return if fight.progress >= 1 then "caught" else nil
end

return ReelFight
