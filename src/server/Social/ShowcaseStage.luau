--!strict
--[[
	ShowcaseStage

	El escenario de cada vitrina de traje (Social/Showcase), en el color del
	traje: pedestal hexagonal de piedra con dos aros de luz y un botón que
	brilla al centro, y un haz de luz que sube del botón hacia el traje. El
	aura está en ShowcaseAura y el cartel en ShowcaseSign. Los clientes hacen
	latir los aros (client/Trajes/Vitrinas).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)

export type Look = {
	main: Color3,
	light: Color3,
	deep: Color3,
	particles: { string },
	tongues: string,
}

local rgb = Color3.fromRGB
local STONE = rgb(58, 54, 60)
local STONE_LIGHT = rgb(92, 86, 94)
local HEX_RADIUS = 7
local HEX_HEIGHT = 1

local ShowcaseStage = {}

ShowcaseStage.LOOKS = table.freeze({
	ReyDelMar = {
		main = rgb(60, 220, 255),
		light = rgb(210, 250, 255),
		deep = rgb(0, 110, 200),
		particles = { Assets.Particles.Burbuja, Assets.Particles.Chispa },
		tongues = Assets.Particles.AguaFlip,
	},
	DiosDelVolcan = {
		main = rgb(255, 150, 30),
		light = rgb(255, 230, 140),
		deep = rgb(220, 50, 0),
		particles = { Assets.Particles.Brasa, Assets.Particles.Chispa },
		tongues = Assets.Particles.FuegoFlip,
	},
} :: { [string]: Look })

function ShowcaseStage.part(
	parent: Instance,
	name: string,
	size: Vector3,
	at: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = at
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanQuery, p.CanTouch = false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Hexágono: tres rectángulos girados 60 grados (cada uno une dos lados opuestos).
local function hexagon(
	parent: Instance,
	name: string,
	radius: number,
	height: number,
	top: Vector3,
	color: Color3
): Part
	local first: Part? = nil
	for i = 0, 2 do
		local at = CFrame.new(top - Vector3.new(0, height / 2, 0))
			* CFrame.Angles(0, math.rad(60 * i), 0)
		local p = ShowcaseStage.part(
			parent,
			name,
			Vector3.new(radius, height, radius * math.sqrt(3)),
			at,
			color,
			Enum.Material.Slate
		)
		first = first or p
	end
	return first :: Part
end

-- Disco plano (cilindro acostado) de radio r, a la altura y.
local function disc(
	parent: Instance,
	name: string,
	r: number,
	y: Vector3,
	color: Color3,
	neon: boolean
): Part
	local at = CFrame.new(y) * CFrame.Angles(0, 0, math.rad(90))
	local d = ShowcaseStage.part(
		parent,
		name,
		Vector3.new(0.04, r * 2, r * 2),
		at,
		color,
		if neon then Enum.Material.Neon else Enum.Material.Slate
	)
	d.Shape = Enum.PartType.Cylinder
	d.CanCollide = false
	return d
end

-- Arma el pedestal en `ground`: devuelve dónde se para el traje, el botón y la pieza del
-- pedestal que lleva el aviso de compra y el cartel.
function ShowcaseStage.pedestal(
	model: Model,
	ground: Vector3,
	look: Look
): (Vector3, BasePart, BasePart)
	hexagon(model, "Zocalo", HEX_RADIUS + 0.7, 0.5, ground + Vector3.new(0, 0.5, 0), STONE_LIGHT)
	local stand = hexagon(
		model,
		"Pedestal",
		HEX_RADIUS,
		HEX_HEIGHT,
		ground + Vector3.new(0, HEX_HEIGHT + 0.3, 0),
		STONE
	)
	local top = ground + Vector3.new(0, HEX_HEIGHT + 0.3, 0)
	local rings = Instance.new("Folder")
	rings.Name = "Aros"
	rings.Parent = model
	for i, r in { 5.6, 5.0, 3.6, 3.0 } do -- aro de luz, piedra, aro, piedra
		disc(
			rings,
			if i % 2 == 1 then "Aro" else "Piedra",
			r,
			top + Vector3.new(0, 0.02 * i, 0),
			if i % 2 == 1 then look.main else STONE,
			i % 2 == 1
		)
	end
	local base = disc(model, "BaseBoton", 1.1, top + Vector3.new(0, 0.2, 0), STONE_LIGHT, false)
	base.Size = Vector3.new(0.3, 2.2, 2.2)
	local button = disc(model, "Boton", 0.75, top + Vector3.new(0, 0.38, 0), look.main, true)
	button.Size = Vector3.new(0.16, 1.5, 1.5)
	return top, button, stand
end

-- Cono de luz corto que sale del botón hasta los pies del traje (no lo tapa) y una luz
-- baja que lo ilumina desde abajo.
function ShowcaseStage.beam(button: BasePart, hover: number, look: Look)
	local from, to = Instance.new("Attachment"), Instance.new("Attachment")
	from.Parent, to.Parent = button, button
	to.WorldPosition = button.Position + Vector3.new(0, hover + 0.4, 0)
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = from, to
	beam.Width0, beam.Width1 = 1.3, 3.2
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(look.light, look.main)
	beam.Transparency = NumberSequence.new(0.35, 1)
	beam.Parent = button
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range = look.main, 1.6, 11
	light.Parent = button
end

return table.freeze(ShowcaseStage)
