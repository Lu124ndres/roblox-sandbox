--!strict
--[[
	Dragon/Cuerpo

	El estado del aleteo, cuadro a cuadro: amplitud (fuerte al subir, en el
	aire quieto y enojado; casi nada al planear), fase (más rápida cuanto más
	fuerte), alas plegadas (picada), patas colgando (quieto en el aire) y la
	boca (abierta al comer o en un truco; se cierra de golpe al morder).
]]

local Etapas = require(script.Parent.Etapas)
local Trucos = require(script.Parent.Trucos)

export type Wings = { phase: number, amp: number, fold: number, hover: number, jaw: number }
export type Input = {
	now: number,
	gliding: number, -- 0..1
	feeding: number, -- 0..1 (suavizado)
	anger: number,
	trick: Trucos.Pose,
	biting: boolean,
}

local Cuerpo = {}

function Cuerpo.new(): Wings
	return { phase = 0, amp = 0.5, fold = 0, hover = 0, jaw = 0 }
end

local function ease(dt: number, rate: number): number
	return 1 - math.exp(-dt * rate)
end

function Cuerpo.update(wings: Wings, dt: number, profile: Etapas.Profile, input: Input)
	local t, w = input.trick, input.feeding
	local wantAmp = profile.amplitude
		* (t.flap or (1 - 0.85 * input.gliding))
		* (1 + 0.3 * w + 0.4 * input.anger)
	wings.amp += (wantAmp - wings.amp) * ease(dt, 3)
	local speedUp = 0.75 + 0.25 * wings.amp / profile.amplitude + 0.3 * w
	wings.phase += dt * 2 * math.pi * profile.beat * speedUp
	wings.fold += ((t.fold or 0) - wings.fold) * ease(dt, 6)
	wings.hover += (math.max(w, t.hover or 0) - wings.hover) * ease(dt, 3)
	local chew = if w > 0.5 then 0.75 + 0.25 * math.sin(input.now * 7) else 0
	local wantJaw = if input.biting then 0 else math.max(t.jaw or 0, chew, 0.08)
	wings.jaw += (wantJaw - wings.jaw) * ease(dt, if input.biting then 30 else 8)
end

return table.freeze(Cuerpo)
