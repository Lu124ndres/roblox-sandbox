--!strict
--[[
	EvolveCharge

	La carga de la evolución (EvolveFx), de 0 a 1 mientras dura:
		- aura: un óvalo de campo de fuerza del color del gigante que crece;
		- energía que converge: chispas que nacen en una esfera alrededor y
		  vuelan hacia el centro (cada vez más);
		- anillos de luz que suben por el cuerpo, cada vez más seguidos;
		- el cuerpo brilla (Highlight) y una luz en el centro se enciende;
		- los bordes de la pantalla se tiñen si el jugador está cerca.
	release() la suelta en el estallido: lo que queda se apaga en la calma.
	Con el modo rápido (light) no hay partículas: aura, brillo y luz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local EvolveParts = require(script.Parent.EvolveParts)

export type Charge = {
	-- center y ground en el mundo, height = alto del gigante, p = carga 0..1, near = 0..1
	update: (
		center: Vector3,
		ground: Vector3,
		height: number,
		p: number,
		near: number,
		body: Instance?
	) -> (),
	release: () -> (),
	destroy: () -> (),
}

local RING_SECONDS = 0.9 -- lo que tarda un anillo en subir el cuerpo

local EvolveCharge = {}

local function fade(instance: Instance, seconds: number, goal: { [string]: any })
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(instance, info, goal):Play()
end

function EvolveCharge.new(
	folder: Instance,
	accent: Color3,
	core: Color3,
	height: number,
	light: boolean,
	rate: number
): Charge
	local aura, auraMesh = EvolveParts.ellipsoid(folder, accent)
	local host = EvolveParts.anchor(folder, Vector3.one * height * 1.5)
	local glow = Instance.new("PointLight")
	glow.Color = accent
	glow.Range = math.min(60, height * 0.8)
	glow.Brightness = 0
	glow.Shadows = false
	glow.Parent = host

	-- Energía que converge: sale de la superficie de la esfera hacia adentro.
	local radius = height * 0.75
	local energy = EvolveParts.emitter(host, Assets.Particles.Chispa, accent, core)
	energy.Shape = Enum.ParticleEmitterShape.Sphere
	energy.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	energy.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	energy.Lifetime = NumberRange.new(0.55, 0.75)
	energy.Speed = NumberRange.new(radius / 0.75, radius / 0.55)
	energy.Orientation = Enum.ParticleOrientation.VelocityParallel
	energy.Size = EvolveParts.sizes(math.min(height * 0.05, 7), 0.4)
	energy.Enabled = not light and rate > 0

	-- Anillos que suben: planos (perpendiculares a su velocidad, que es hacia arriba).
	local base = Instance.new("Attachment")
	base.Parent = host
	local rings = EvolveParts.emitter(base, Assets.Particles.Anillo, accent, core)
	rings.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	rings.EmissionDirection = Enum.NormalId.Top
	rings.Lifetime = NumberRange.new(RING_SECONDS)
	rings.Speed = NumberRange.new(height / RING_SECONDS)
	rings.SpreadAngle = Vector2.zero
	rings.RotSpeed = NumberRange.new(0)
	local ringSize = math.min(height * 0.62, 95)
	rings.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, ringSize * 0.5),
		NumberSequenceKeypoint.new(0.25, ringSize),
		NumberSequenceKeypoint.new(1, ringSize * 0.45),
	})
	rings.Transparency = NumberSequence.new(0.1, 1)

	local shine = Instance.new("Highlight")
	shine.Name = "BrilloEvolucion"
	shine.FillColor = accent
	shine.OutlineColor = core
	shine.FillTransparency = 1
	shine.OutlineTransparency = 1
	shine.DepthMode = Enum.HighlightDepthMode.Occluded
	shine.Parent = folder

	local vignette =
		EvolveParts.vignette(Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"), accent)

	local nextRing = 0
	local released = false
	return {
		update = function(center, ground, size, p, near, body)
			shine.Adornee = body -- también después del estallido: el modelo nuevo destella
			if released then
				return
			end
			host.CFrame = CFrame.new(center)
			base.WorldPosition = ground
			aura.CFrame = CFrame.new(center)
			local grow = 0.8 + 0.3 * p
			auraMesh.Scale = Vector3.new(size * 0.62, size * 1.12, size * 0.62) * grow
			aura.Transparency = 1 - 0.7 * math.sqrt(p)
			glow.Brightness = 1 + 7 * p * p
			energy.Rate = (25 + 160 * p) * rate
			shine.FillTransparency = 1 - 0.6 * p
			shine.OutlineTransparency = 1 - 0.9 * p
			if vignette then
				vignette.ImageTransparency = 1 - 0.65 * p * near
			end
			if not light and rate > 0 and os.clock() >= nextRing then
				rings:Emit(1)
				nextRing = os.clock() + 0.32 - 0.2 * p
			end
		end,
		release = function()
			released = true
			energy.Enabled = false
			fade(aura, 0.9, { Transparency = 1 })
			fade(auraMesh, 0.9, { Scale = auraMesh.Scale * 1.6 })
			glow.Brightness = 14
			fade(glow, 1.6, { Brightness = 0 })
			shine.FillColor = Color3.new(1, 1, 1)
			shine.FillTransparency = 0
			shine.OutlineTransparency = 0
			fade(shine, 1.3, { FillTransparency = 1, OutlineTransparency = 1 })
			if vignette then
				fade(vignette, 0.7, { ImageTransparency = 1 })
			end
		end,
		destroy = function()
			shine:Destroy()
			if vignette then
				local layer = vignette.Parent
				if layer then
					layer:Destroy()
				end
			end
		end,
	}
end

return table.freeze(EvolveCharge)
