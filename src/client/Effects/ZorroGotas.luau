--!strict
--[[
	ZorroGotas

	Agua del zorro al comer (todo partículas: en modo rápido, fxScale = 0, no
	sale ninguna; el tamaño sigue al alto del zorro):
		drops    gotas que saltan de la boca al atrapar un pez (con destellos cian
		         si el pez es raro)
		glitter  gotas y burbujas brillantes que salen en arco a su alrededor y
		         caen (pez raro y salto mortal); más cuanto más raro
		paws     salpicadura chica de cada pata al correr (la estela)
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local WATER = Color3.fromRGB(150, 225, 245)
local CYAN = Color3.fromRGB(110, 255, 240)
local FOAM = Color3.fromRGB(230, 250, 255)

local ZorroGotas = {}

local function anchor(position: Vector3, lifetime: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "AguaZorro"
	attachment.WorldPosition = position
	attachment.Parent = Workspace.Terrain
	Debris:AddItem(attachment, lifetime)
	return attachment
end

type Spec = {
	texture: string,
	color: ColorSequence,
	size: number,
	speed: NumberRange,
	spread: number,
	gravity: number,
	lifetime: NumberRange,
	light: number,
}

-- Una ráfaga: en modo rápido no sale nada.
local function burst(parent: Instance, spec: Spec, count: number)
	local amount = math.round(count * ClientSettings.fxScale())
	if amount <= 0 then
		return
	end
	local p = Instance.new("ParticleEmitter")
	p.Texture = spec.texture
	p.Color = spec.color
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, spec.size * 0.6),
		NumberSequenceKeypoint.new(0.2, spec.size),
		NumberSequenceKeypoint.new(1, spec.size * 0.2),
	})
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.75, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.Speed = spec.speed
	p.SpreadAngle = Vector2.new(spec.spread, spec.spread)
	p.Acceleration = Vector3.new(0, -spec.gravity, 0)
	p.Lifetime = spec.lifetime
	p.LightEmission = spec.light
	p.Rotation = NumberRange.new(0, 360)
	p.RotSpeed = NumberRange.new(-60, 60)
	p.EmissionDirection = Enum.NormalId.Top
	p.Rate = 0
	p.Enabled = false
	p.Parent = parent
	p:Emit(amount)
end

-- height: alto del zorro; power: rareza del pez (1 común).
function ZorroGotas.drops(mouth: Vector3, height: number, power: number)
	local at = anchor(mouth, 2)
	local h = height
	burst(at, {
		texture = Assets.Particles.Sparkle,
		color = ColorSequence.new(WATER),
		size = 0.035 * h,
		speed = NumberRange.new(0.25 * h, 0.5 * h),
		spread = 70,
		gravity = 1.6 * h,
		lifetime = NumberRange.new(0.4, 0.7),
		light = 0.3,
	}, 8 + 2 * power)
	if power >= 3 then
		burst(at, {
			texture = Assets.Particles.Chispa,
			color = ColorSequence.new(CYAN, FOAM),
			size = 0.05 * h,
			speed = NumberRange.new(0.15 * h, 0.35 * h),
			spread = 180,
			gravity = 0,
			lifetime = NumberRange.new(0.6, 1),
			light = 1,
		}, 4 * power)
	end
end

function ZorroGotas.glitter(center: Vector3, height: number, power: number)
	local h = height
	local at = anchor(center + Vector3.new(0, 0.55 * h, 0), 3)
	local much = math.clamp(power - 1, 1, 5)
	burst(at, {
		texture = Assets.Particles.Burbuja,
		color = ColorSequence.new(FOAM, CYAN),
		size = 0.06 * h,
		speed = NumberRange.new(0.6 * h, 1 * h),
		spread = 75,
		gravity = 1.1 * h,
		lifetime = NumberRange.new(1.2, 1.8),
		light = 0.6,
	}, 6 + 4 * much)
	burst(at, {
		texture = Assets.Particles.Chispa,
		color = ColorSequence.new(CYAN, Color3.new(1, 1, 1)),
		size = 0.045 * h,
		speed = NumberRange.new(0.4 * h, 0.8 * h),
		spread = 90,
		gravity = 0.6 * h,
		lifetime = NumberRange.new(0.9, 1.4),
		light = 1,
	}, 6 + 5 * much)
end

function ZorroGotas.paws(position: Vector3, height: number)
	burst(anchor(position, 1.5), {
		texture = Assets.Particles.Sparkle,
		color = ColorSequence.new(FOAM, WATER),
		size = 0.03 * height,
		speed = NumberRange.new(0.15 * height, 0.3 * height),
		spread = 40,
		gravity = 1.4 * height,
		lifetime = NumberRange.new(0.35, 0.6),
		light = 0.3,
	}, 5)
end

return table.freeze(ZorroGotas)
