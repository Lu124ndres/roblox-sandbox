--!strict
--[[
	OrcaFx/Fantasma

	El toque espectral de la Orca fantasma cuando come (solo en el cliente):
		pulse   se vuelve más transparente un instante y vuelve (las piezas del
		        modelo, con LocalTransparencyModifier: no pisa su Transparency)
		sweep   un brillo menta la atraviesa de la boca a la punta de la cola
		        siguiendo sus huesos (luz y chispas que quedan atrás)
	Con efectos reducidos (fxScale = 0) no hay luz ni chispas; la
	transparencia sí (no cuesta nada).
]]

local Workspace = game:GetService("Workspace")

local Assets = require(script.Parent.Parent.Parent.Assets)
local Rig = require(script.Parent.Parent.OrcaMotion.Rig)

local MAX_FADE = 0.7 -- lo más transparente que se pone
local FADE_BACK = 1.6 -- 1/s: qué tan rápido vuelve a verse entera
local PATH = { "Boca", "Cabeza", "Pecho", "Raiz", "Cola1", "Cola2", "Cola3", "Cola4" }

local Colors = table.freeze({
	Violet = Color3.fromRGB(175, 110, 255),
	Mint = Color3.fromRGB(130, 255, 205),
	Pumpkin = Color3.fromRGB(255, 140, 26),
	Magenta = Color3.fromRGB(242, 77, 217),
})

export type Fantasma = {
	rig: Rig.Rig,
	parts: { BasePart },
	fade: number, -- a dónde va la transparencia
	shown: number, -- la que tiene ahora
	written: number, -- la que se puso en las piezas (se escribe solo si cambia)
	sweepT: number,
	sweepSeconds: number,
	anchor: Attachment,
	light: PointLight,
	motes: ParticleEmitter,
	sizedFor: number, -- alto con que se midieron las chispas
}

local Fantasma = {}
Fantasma.Colors = Colors

function Fantasma.attach(rig: Rig.Rig): Fantasma
	local parts: { BasePart } = {}
	local root = rig.bones.Raiz
	local model = root and root:FindFirstAncestorOfClass("Model")
	if model then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
	end
	local anchor = Instance.new("Attachment")
	anchor.Name = "BrilloFantasma"
	anchor.Parent = Workspace.Terrain
	local light = Instance.new("PointLight")
	light.Color = Colors.Mint
	light.Brightness = 0
	light.Shadows = false
	light.Parent = anchor
	local motes = Instance.new("ParticleEmitter")
	motes.Texture = Assets.Particles.Sparkle
	motes.Color = ColorSequence.new(Colors.Mint, Colors.Violet)
	motes.LightEmission = 1
	motes.Transparency = NumberSequence.new(0.1, 1)
	motes.Lifetime = NumberRange.new(0.5, 0.9)
	motes.SpreadAngle = Vector2.new(180, 180)
	motes.Drag = 4
	motes.Rate = 0
	motes.Parent = anchor
	return {
		rig = rig,
		parts = parts,
		fade = 0,
		shown = 0,
		written = 0,
		sweepT = 1,
		sweepSeconds = 1,
		anchor = anchor,
		light = light,
		motes = motes,
		sizedFor = 0,
	}
end

function Fantasma.pulse(g: Fantasma, amount: number)
	g.fade = math.clamp(math.max(g.fade, amount), 0, MAX_FADE)
end

function Fantasma.sweep(g: Fantasma, seconds: number)
	g.sweepT, g.sweepSeconds = 0, seconds
end

-- Punto del recorrido boca -> cola en el avance s (0..1).
local function along(rig: Rig.Rig, s: number): Vector3?
	local points: { Vector3 } = {}
	for _, name in PATH do
		local point = Rig.point(rig, name)
		if point then
			table.insert(points, point)
		end
	end
	if #points == 0 then
		return nil
	elseif #points == 1 then
		return points[1]
	end
	local x = s * (#points - 1)
	local k = math.min(math.floor(x) + 1, #points - 1)
	return points[k]:Lerp(points[k + 1], x - (k - 1))
end

function Fantasma.update(g: Fantasma, dt: number, height: number, fxScale: number)
	g.fade *= math.exp(-dt * FADE_BACK)
	g.shown += (g.fade - g.shown) * (1 - math.exp(-dt * 20))
	if g.shown < 0.005 then
		g.shown = 0
	end
	if math.abs(g.shown - g.written) > 0.004 or (g.shown == 0 and g.written ~= 0) then
		g.written = g.shown
		for _, part in g.parts do
			part.LocalTransparencyModifier = g.shown
		end
	end
	local sweeping = g.sweepT < g.sweepSeconds
	if sweeping then
		g.sweepT += dt
		local u = math.clamp(g.sweepT / g.sweepSeconds, 0, 1)
		local point = along(g.rig, u * u * (3 - 2 * u))
		if point then
			g.anchor.WorldPosition = point
		end
		g.light.Range = math.clamp(height * 0.8, 8, 60)
		g.light.Brightness = if fxScale > 0 then 4 * math.sin(math.pi * u) else 0
	else
		g.light.Brightness = 0
	end
	if math.abs(height / math.max(g.sizedFor, 1) - 1) > 0.05 then
		g.sizedFor = height
		g.motes.Size = NumberSequence.new(0.6 * height / 16.5, 0)
	end
	g.motes.Rate = if sweeping then 50 * fxScale else 0
end

function Fantasma.destroy(g: Fantasma)
	for _, part in g.parts do
		if part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
	g.anchor:Destroy()
end

return table.freeze(Fantasma)
