--!strict
--[[
	ZorroRafagas

	Las ráfagas de agua y de hielo del zorro de agua v2 (las usa ZorroAgua).
	Todas son partículas en un punto del mundo que se limpia solo; la cantidad
	se escala con ClientSettings.fxScale() (modo rápido: ninguna) y el tamaño
	sigue al alto del zorro:
		drops(punto, alto, n)     gotas que salen para todos lados (se sacude)
		crown(punto, alto, n)     corona de espuma al caer de un salto (el golpe
		                          en el agua lo pone GroundFx)
		foam(punto, alto, n)      espuma que salpica de la punta de una cola
		glints(punto, alto, n)    destellos de hielo (desde el adulto)
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local MAX_BURST = 60
local rgb = Color3.fromRGB
local LIGHT = rgb(143, 227, 247) -- claro del cuerpo
local FOAM = rgb(230, 247, 255) -- espuma (sin blanco puro)
local FOAM_SHADE = rgb(196, 234, 248)
local ICE = rgb(191, 243, 255)

type Spec = {
	texture: string,
	color: ColorSequence,
	size: number, -- en altos del zorro
	speed: number, -- en altos por segundo
	spread: number,
	gravity: number, -- en altos por segundo²
	lifetime: NumberRange,
	light: number,
}

local ZorroRafagas = {}

local function emit(position: Vector3, height: number, spec: Spec, count: number)
	local amount = math.min(MAX_BURST, math.round(count * ClientSettings.fxScale()))
	if amount <= 0 then
		return
	end
	local holder = Instance.new("Attachment")
	holder.Name = "AguaZorroV2"
	holder.WorldPosition = position
	holder.Parent = Workspace.Terrain
	Debris:AddItem(holder, spec.lifetime.Max + 0.5)
	local h, s = height, spec.size * height
	local p = Instance.new("ParticleEmitter")
	p.Texture = spec.texture
	p.Color = spec.color
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, s * 0.6),
		NumberSequenceKeypoint.new(0.2, s),
		NumberSequenceKeypoint.new(1, s * 0.15),
	})
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.Speed = NumberRange.new(spec.speed * h * 0.6, spec.speed * h)
	p.SpreadAngle = Vector2.new(spec.spread, spec.spread)
	p.Acceleration = Vector3.new(0, -spec.gravity * h, 0)
	p.Lifetime = spec.lifetime
	p.LightEmission = spec.light
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-80, 80)
	p.EmissionDirection = Enum.NormalId.Top
	p.Rate = 0
	p.Enabled = false
	p.Parent = holder
	p:Emit(amount)
end

function ZorroRafagas.drops(position: Vector3, height: number, count: number)
	emit(position, height, {
		texture = Assets.Particles.Sparkle,
		color = ColorSequence.new(FOAM, LIGHT),
		size = 0.03,
		speed = 0.55,
		spread = 180,
		gravity = 1.5,
		lifetime = NumberRange.new(0.5, 0.9),
		light = 0.35,
	}, count)
end

function ZorroRafagas.crown(position: Vector3, height: number, count: number)
	emit(position, height, {
		texture = Assets.Particles.Burbuja,
		color = ColorSequence.new(FOAM, FOAM_SHADE),
		size = 0.05,
		speed = 0.7,
		spread = 35,
		gravity = 1.8,
		lifetime = NumberRange.new(0.6, 1),
		light = 0.3,
	}, count)
	emit(position, height, {
		texture = Assets.Particles.Mist,
		color = ColorSequence.new(FOAM),
		size = 0.12,
		speed = 0.2,
		spread = 80,
		gravity = 0.1,
		lifetime = NumberRange.new(0.8, 1.3),
		light = 0.2,
	}, math.ceil(count / 3))
end

function ZorroRafagas.foam(position: Vector3, height: number, count: number)
	emit(position, height, {
		texture = Assets.Particles.Burbuja,
		color = ColorSequence.new(FOAM, FOAM_SHADE),
		size = 0.025,
		speed = 0.18,
		spread = 120,
		gravity = 0.9,
		lifetime = NumberRange.new(0.4, 0.8),
		light = 0.4,
	}, count)
end

function ZorroRafagas.glints(position: Vector3, height: number, count: number)
	emit(position, height, {
		texture = Assets.Particles.Chispa,
		color = ColorSequence.new(ICE, FOAM),
		size = 0.03,
		speed = 0.12,
		spread = 180,
		gravity = 0,
		lifetime = NumberRange.new(0.5, 0.9),
		light = 1,
	}, count)
end

return table.freeze(ZorroRafagas)
