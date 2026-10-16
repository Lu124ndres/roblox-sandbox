--!strict
--[[
	Trajes/Estilos/ReyDelMar

	Majestuoso: camina derecho, con poco vaivén de brazos, la barbilla en
	alto y mirando despacio su reino. En la vitrina alza el tridente.
	Efectos: el tridente brilla y gotea agua, y burbujas a sus pies.
]]

local Tipos = require(script.Parent.Parent.Tipos)

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local WATER = Color3.fromRGB(110, 220, 255)

local function pulse(now: number, every: number, length: number): number
	local t = now % every
	return if t < length then math.sin(math.pi * t / length) ^ 0.6 else 0
end

local function drops(size: number, rate: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.Color = ColorSequence.new(WATER, Color3.fromRGB(230, 250, 255))
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new(0.15)
	e.LightEmission = 0.7
	e.Rate = rate
	return e
end

local style: Tipos.Style = {
	arms = 0.75,
	legs = 0.9,
	pose = function(ctx: Tipos.Context): { [string]: CFrame }
		local now = ctx.now
		local still = math.clamp(1 - ctx.speed / 8, 0, 1)
		local pose = {
			Pecho = CFrame.Angles(0.03 + 0.02 * math.sin(now * 1.3), 0, 0),
			Cabeza = CFrame.Angles(0.07, 0.28 * math.sin(now * 0.33) * still, 0),
		}
		if not ctx.display then
			return pose
		end
		local w = pulse(now, 7, 2.8)
		if w > 0 then -- alza el tridente
			pose.BrazoDer = CFrame.Angles(2.3 * w, 0, 0.25 * w)
			pose.BrazoIzq = CFrame.Angles(0, 0, -0.35 * w)
			pose.Cabeza = CFrame.Angles(0.07 + 0.22 * w, 0, 0)
		end
		return pose
	end,
	effects = function(fx: Tipos.Fx)
		local h = fx.height
		local tip = fx.socket("ManoDer", Vector3.new(0.08, 0.47, -0.15))
		if tip then
			local light = Instance.new("PointLight")
			light.Color = WATER
			light.Brightness = 1.4
			light.Range = 1.3 * h
			light.Parent = tip
			local drip = drops(0.035 * h, 8)
			drip.Lifetime = NumberRange.new(0.6, 1.2)
			drip.Speed = NumberRange.new(0, 0.06 * h)
			drip.SpreadAngle = Vector2.new(180, 180)
			drip.Acceleration = Vector3.new(0, -0.7 * h, 0)
			drip.Parent = tip
			fx.emitter(drip)
		end
		local feet = fx.socket("Raiz", Vector3.new(0, 0.02, 0))
		if feet then
			local bubbles = drops(0.03 * h, 6)
			bubbles.Lifetime = NumberRange.new(0.8, 1.5)
			bubbles.Speed = NumberRange.new(0.1 * h, 0.2 * h)
			bubbles.SpreadAngle = Vector2.new(70, 70)
			bubbles.Parent = feet
			fx.emitter(bubbles)
		end
	end,
}

return style
