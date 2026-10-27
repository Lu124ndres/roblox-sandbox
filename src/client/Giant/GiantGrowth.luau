--!strict
--[[
	GiantGrowth

	El alto del monstruo en el cliente, que crece con cada pez (pedido del
	usuario: que aumente bien y natural):
		objetivo  GiantStages.heightAt(barra, etapa que se ve): dentro de la etapa
		          no pasa de su tope (el último estirón llega con la evolución) y
		          nunca baja (si se enoja y la barra baja, no encoge)
		resorte   el alto va hacia el objetivo con un resorte amortiguado: arranca
		          suave, toma velocidad y frena suave, sin pasarse (antes saltaba a
		          toda velocidad y se frenaba, y en los saltos grandes se notaba)
		bocado    al tragar se infla un poquito y vuelve (swell), a lo sumo cada
		          GiantGulpGap segundos para que el chorro de peces no lo haga temblar
	El alto (height) no incluye el bocado: lo que nada, vuela o se para lo usa
	sin temblar; el bocado solo se suma a la escala del modelo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

local EFFECTS = UIConfig.Effects
local MAX_DT = 0.05 -- un cuadro largo (tirón) no dispara el resorte

export type Growth = {
	height: () -> number, -- alto actual (sin el bocado)
	swell: () -> number, -- inflado del bocado (0 = nada; 0.02 = 2 % más grande)
	settled: () -> boolean, -- ya llegó y no está tragando
	setStage: (stage: number, instant: boolean?) -> (),
	grow: (progress: number, instant: boolean?) -> (),
	gulp: () -> (),
	step: (dt: number) -> (),
}

local GiantGrowth = {}

function GiantGrowth.new(): Growth
	local height = GiantStages.heightFor(1)
	local target, velocity = height, 0
	local stage, progress = 1, 0
	local gulpAt, now = -math.huge, 0
	-- Resorte críticamente amortiguado: llega cerca del objetivo en ~GiantGrowthSeconds.
	local omega = 4 / EFFECTS.GiantGrowthSeconds

	local function aim(instant: boolean?)
		local wanted = GiantStages.heightAt(progress, stage)
		target = math.max(target, GiantStages.heightFor(stage), wanted)
		if instant then
			height, velocity = target, 0
		end
	end

	local function swell(): number
		local t = (now - gulpAt) / EFFECTS.GiantGulpSeconds
		return if t >= 0 and t < 1 then EFFECTS.GiantGulpSwell * math.sin(math.pi * t) else 0
	end

	return {
		height = function()
			return height
		end,
		swell = swell,
		settled = function()
			return height == target and swell() == 0
		end,
		setStage = function(newStage: number, instant: boolean?)
			stage = newStage
			if instant then
				target = 0 -- otro comienzo: se mide de nuevo
			end
			aim(instant)
		end,
		grow = function(newProgress: number, instant: boolean?)
			progress = newProgress
			aim(instant)
		end,
		gulp = function()
			if now - gulpAt >= EFFECTS.GiantGulpGap then
				gulpAt = now
			end
		end,
		step = function(dt: number)
			dt = math.min(dt, MAX_DT)
			now += dt
			if height == target then
				return
			end
			local accel = omega * omega * (target - height) - 2 * omega * velocity
			velocity += accel * dt
			height += velocity * dt
			if math.abs(target - height) < target * 1e-3 and math.abs(velocity) < target * 1e-2 then
				height, velocity = target, 0 -- llegó
			end
		end,
	}
end

return table.freeze(GiantGrowth)
