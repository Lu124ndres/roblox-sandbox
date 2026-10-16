--!strict
--[[
	Trajes/Estilos/DiosDelVolcan

	Pesado y amenazante: brazos y piernas con menos vaivén, el cuerpo se
	inclina hacia adelante al caminar, respira hondo y mira despacio a los
	lados. En la vitrina saca músculo con los dos brazos y ruge.
	Efectos: humo y chispas del volcán de la cabeza, brillo de lava en el
	pecho y gotas de lava en las manos.
]]

local Tipos = require(script.Parent.Parent.Tipos)

local PARTICLES = {
	Mist = "rbxasset://textures/particles/smoke_main.dds",
	Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
}
local LAVA = Color3.fromRGB(255, 120, 30)

local function pulse(now: number, every: number, length: number): number
	local t = now % every
	return if t < length then math.sin(math.pi * t / length) ^ 0.6 else 0
end

local function emitter(
	texture: string,
	color: ColorSequence,
	size: number,
	rate: number
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = color
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, size * 2.2),
	})
	e.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Rate = rate
	e.LightEmission = 0.4
	e.LockedToPart = false
	return e
end

local style: Tipos.Style = {
	arms = 0.8,
	legs = 0.85,
	pose = function(ctx: Tipos.Context): { [string]: CFrame }
		local now = ctx.now
		local move = math.clamp(ctx.speed / 16, 0, 1)
		local still = 1 - move
		local pose = {
			Pecho = CFrame.Angles(-0.13 * move + 0.045 * math.sin(now * 1.1), 0, 0),
			Cabeza = CFrame.Angles(0.05 * move, 0.3 * math.sin(now * 0.28) * still, 0),
		}
		if not ctx.display then
			return pose
		end
		local w = pulse(now, 8, 3.2)
		if w > 0 then -- doble bíceps y rugido
			pose.BrazoIzq = CFrame.Angles(0, 0, -1.45 * w)
			pose.BrazoDer = CFrame.Angles(0, 0, 1.45 * w)
			pose.CodoIzq = CFrame.Angles(0, 0, -1.5 * w)
			pose.CodoDer = CFrame.Angles(0, 0, 1.5 * w)
			pose.Pecho = pose.Pecho * CFrame.Angles(0.1 * w, 0, 0)
			pose.Cabeza = CFrame.Angles(0.3 * w + 0.03 * math.sin(now * 30) * w, 0, 0)
		end
		return pose
	end,
	effects = function(fx: Tipos.Fx)
		local h = fx.height
		local top = fx.socket("Cabeza", Vector3.new(0, 0.36, 0))
		if top then
			local smoke =
				emitter(PARTICLES.Mist, ColorSequence.new(Color3.fromRGB(70, 60, 58)), 0.12 * h, 6)
			smoke.Lifetime = NumberRange.new(1.4, 2.4)
			smoke.Speed = NumberRange.new(0.25 * h, 0.4 * h)
			smoke.SpreadAngle = Vector2.new(12, 12)
			smoke.LightEmission = 0
			smoke.Parent = top
			fx.emitter(smoke)
			local sparks = emitter(PARTICLES.Spark, ColorSequence.new(LAVA), 0.03 * h, 5)
			sparks.Lifetime = NumberRange.new(0.6, 1.1)
			sparks.Speed = NumberRange.new(0.3 * h, 0.55 * h)
			sparks.SpreadAngle = Vector2.new(25, 25)
			sparks.Acceleration = Vector3.new(0, -0.6 * h, 0)
			sparks.LightEmission = 1
			sparks.Parent = top
			fx.emitter(sparks)
		end
		local chest = fx.socket("Pecho", Vector3.new(0, 0.08, -0.1))
		if chest then
			local light = Instance.new("PointLight")
			light.Color = LAVA
			light.Brightness = 1.6
			light.Range = 1.6 * h
			light.Parent = chest
		end
		for _, side in { "Izq", "Der" } do
			local hand = fx.socket("Mano" .. side, Vector3.new(0, -0.03, 0))
			if hand then
				local drip = emitter(PARTICLES.Spark, ColorSequence.new(LAVA), 0.025 * h, 3)
				drip.Lifetime = NumberRange.new(0.5, 0.9)
				drip.Speed = NumberRange.new(0, 0.05 * h)
				drip.Acceleration = Vector3.new(0, -1.2 * h, 0)
				drip.LightEmission = 1
				drip.Parent = hand
				fx.emitter(drip)
			end
		end
	end,
}

return style
