--!strict
--[[
	ZorroPuntas

	Los emisores de las puntas de las colas del zorro de agua v2 (los usa
	ZorroAgua). Van en el último hueso de cada cola (_5, o _4 en el modelo
	viejo), así siguen la animación, y las partículas quedan en el mundo:
		espuma  salpica cuando la punta se mueve rápido (más cuanto más rápido);
		        se emite a mano, escalada con fxScale (modo rápido: nada)
		hielo   desde el adulto, unos pocos destellos de hielo por segundo
		        (emisor continuo registrado en FxQuality)
		new(rig)
		update(p, dt, alto, etapa, visible)
		positions(p) -> { Vector3 }    dónde está cada punta ahora
		destroy(p)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Rig = require(ReplicatedStorage.Shared.Zorro.Rig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

local FOAM_SPEED = 0.8 -- altos del zorro por segundo: desde ahí la punta salpica
local FOAM_RATE = 14 -- partículas por segundo por cada alto/s de más
local MAX_PER_FRAME = 6
local GLINT_RATE = { 0, 0, 0.6, 1.2 } -- destellos de hielo por segundo y punta, por etapa
local rgb = Color3.fromRGB
local FOAM = rgb(230, 247, 255)
local ICE = rgb(191, 243, 255)

type Tip =
	{ bone: Bone, foam: ParticleEmitter, glint: ParticleEmitter, last: Vector3?, acc: number }
export type Puntas = { tips: { Tip }, sizedFor: number, glintStage: number }

local ZorroPuntas = {}

local function emitter(parent: Bone, name: string, texture: string): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Name = name
	p.Texture = texture
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-60, 60)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Rate = 0
	p.Parent = parent
	return p
end

-- Tamaño y velocidad de los emisores de una punta para este alto.
local function fit(tip: Tip, height: number)
	tip.foam.Size = NumberSequence.new(0.03 * height, 0.008 * height)
	tip.foam.Speed = NumberRange.new(0.05 * height, 0.15 * height)
	tip.foam.Acceleration = Vector3.new(0, -0.8 * height, 0)
	tip.glint.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.035 * height),
		NumberSequenceKeypoint.new(1, 0),
	})
	tip.glint.Speed = NumberRange.new(0.01 * height, 0.04 * height)
end

function ZorroPuntas.new(rig: Rig.Rig): Puntas
	local list = {}
	for _, tail in rig.tails do
		local bone = rig.bones[`{tail.prefix}5`] or rig.bones[`{tail.prefix}4`]
		if bone then
			local foam = emitter(bone, "Espuma", Assets.Particles.Burbuja)
			foam.Color = ColorSequence.new(FOAM)
			foam.Lifetime = NumberRange.new(0.4, 0.8)
			foam.LightEmission = 0.4
			local glint = emitter(bone, "Hielo", Assets.Particles.Chispa)
			glint.Color = ColorSequence.new(ICE, FOAM)
			glint.Lifetime = NumberRange.new(0.6, 1.1)
			glint.LightEmission = 1
			glint.LightInfluence = 0
			FxQuality.scaleEmitter(glint)
			table.insert(list, { bone = bone, foam = foam, glint = glint, last = nil, acc = 0 })
		end
	end
	return { tips = list, sizedFor = 0, glintStage = -1 }
end

-- El ritmo base del hielo cambia con la etapa: FxQuality lo vuelve a escalar.
local function setGlints(p: Puntas, stage: number)
	if stage == p.glintStage then
		return
	end
	p.glintStage = stage
	for _, tip in p.tips do
		tip.glint:SetAttribute("RitmoBase", GLINT_RATE[stage] or 0)
		FxQuality.scaleEmitter(tip.glint)
	end
end

function ZorroPuntas.update(p: Puntas, dt: number, height: number, stage: number, visible: boolean)
	setGlints(p, if visible then stage else 0)
	if math.abs(height - p.sizedFor) > p.sizedFor * 0.01 then
		p.sizedFor = height
		for _, tip in p.tips do
			fit(tip, height)
		end
	end
	local fx = ClientSettings.fxScale()
	for _, tip in p.tips do
		local now = tip.bone.TransformedWorldCFrame.Position
		if visible and fx > 0 and tip.last and dt > 0 then
			local speed = (now - tip.last).Magnitude / dt / height
			tip.acc += math.max(0, speed - FOAM_SPEED) * FOAM_RATE * dt * fx
			if tip.acc >= 1 then
				local n = math.floor(tip.acc)
				tip.acc -= n
				tip.foam:Emit(math.min(n, MAX_PER_FRAME))
			end
		else
			tip.acc = 0
		end
		tip.last = now
	end
end

function ZorroPuntas.positions(p: Puntas): { Vector3 }
	local list = {}
	for _, tip in p.tips do
		table.insert(list, tip.bone.TransformedWorldCFrame.Position)
	end
	return list
end

function ZorroPuntas.destroy(p: Puntas)
	for _, tip in p.tips do
		tip.foam:Destroy()
		tip.glint:Destroy()
	end
end

return table.freeze(ZorroPuntas)
