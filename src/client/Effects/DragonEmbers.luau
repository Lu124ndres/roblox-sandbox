--!strict
--[[
	DragonEmbers

	Brasas que se escapan de las grietas de fuego del cuerpo en las etapas
	grandes (adulto y anciano): unos pocos puntos al rojo que salen del pecho,
	el cuello, la cadera y la cola, suben con el calor y se apagan. Van en
	huesos nuevos (Grieta) hijos de esos huesos (siguen la animación) y las partículas
	quedan en el mundo (el dragón vuela y dejan un rastro tenue). Ritmo bajo y
	registrado en FxQuality: en modo rápido no sale ninguna.
		build(rig, etapa, largo)  nil en la cría y el joven
		show(e, encendidas)       se apagan cuando el dragón está escondido
		destroy(e)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Rig = require(ReplicatedStorage.Shared.Dragon.Rig)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

local BONES = { "Pecho", "Cuello2", "Cadera", "Cola2" }
local RATE = { [3] = 1.5, [4] = 3 } -- brasas por segundo en cada hueso
local rgb = Color3.fromRGB

export type Embers = { holders: { Bone }, emitters: { ParticleEmitter }, on: boolean }

local DragonEmbers = {}

local function emitter(parent: Bone, length: number, rate: number): ParticleEmitter
	local ember = Instance.new("ParticleEmitter")
	ember.Name = "Brasas"
	ember.Texture = Assets.Particles.Brasa
	ember.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(255, 230, 140)),
		ColorSequenceKeypoint.new(0.5, rgb(255, 120, 30)),
		ColorSequenceKeypoint.new(1, rgb(140, 25, 10)),
	})
	ember.LightEmission = 1
	ember.LightInfluence = 0
	ember.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.012 * length),
		NumberSequenceKeypoint.new(0.6, 0.009 * length),
		NumberSequenceKeypoint.new(1, 0),
	})
	ember.Lifetime = NumberRange.new(1.2, 2.2)
	ember.Speed = NumberRange.new(0.02 * length, 0.06 * length)
	ember.SpreadAngle = Vector2.new(180, 180)
	ember.Acceleration = Vector3.new(0, 0.08 * length, 0)
	ember.Drag = 1
	ember.Rate = rate
	ember.Parent = parent
	FxQuality.scaleEmitter(ember)
	return ember
end

function DragonEmbers.build(rig: Rig.Rig, stage: number, length: number): Embers?
	local rate = RATE[stage]
	if not rate then
		return nil
	end
	local holders, emitters = {}, {}
	for _, name in BONES do
		local bone = rig.bones[name]
		if bone then
			local holder = Instance.new("Bone")
			holder.Name = "Grieta"
			holder.Parent = bone
			table.insert(holders, holder)
			table.insert(emitters, emitter(holder, length, rate))
		end
	end
	return if #holders > 0 then { holders = holders, emitters = emitters, on = true } else nil
end

function DragonEmbers.show(e: Embers, on: boolean)
	if e.on == on then
		return
	end
	e.on = on
	for _, ember in e.emitters do
		ember.Enabled = on
	end
end

function DragonEmbers.destroy(e: Embers)
	for _, holder in e.holders do
		holder:Destroy()
	end
end

return table.freeze(DragonEmbers)
