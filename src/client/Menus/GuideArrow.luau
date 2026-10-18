--!strict
--[[
	GuideArrow

	La flecha verde de la guía (como la de los simuladores): flota junto al
	jugador, a la altura del cuerpo, lo sigue a todos lados y apunta hacia el
	siguiente punto del camino (GuidePath). Es gruesa, con contorno negro
	(Highlight) para leerse sobre cualquier fondo, sube y baja suave y empuja
	un poco hacia adelante, como diciendo «por acá». Solo existe en este
	cliente; no hay nada puesto en el mapa.
]]

local Workspace = game:GetService("Workspace")

local GREEN = Color3.fromRGB(80, 235, 90)
local DISTANCE = 5.5 -- studs delante del jugador, hacia donde apunta: no lo tapa el cuerpo
local HEIGHT = 1.3 -- respecto del centro del cuerpo: a la altura del pecho, sobre el pasto alto
local BOB = 0.35
local NUDGE = 0.5 -- cuánto empuja hacia adelante y vuelve

export type Arrow = {
	place: (root: Vector3, direction: Vector3, t: number) -> (),
	show: (visible: boolean) -> (),
}

local GuideArrow = {}

local function piece(name: string, size: Vector3, offset: CFrame, model: Model): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = GREEN
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	part:SetAttribute("Desfase", offset)
	part.Parent = model
	return part
end

function GuideArrow.new(): Arrow
	local model = Instance.new("Model")
	model.Name = "FlechaGuia"
	-- Apunta hacia -Z (el LookVector): un cuerpo y una punta de rombo.
	local parts = {
		piece("Cuerpo", Vector3.new(1.4, 0.7, 2.8), CFrame.new(0, 0, 1.4), model),
		piece(
			"Punta",
			Vector3.new(2.5, 0.7, 2.5),
			CFrame.new(0, 0, -0.45) * CFrame.Angles(0, math.rad(45), 0),
			model
		),
	}
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(10, 10, 14)
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
	model.Parent = Workspace

	local visible = true
	local function show(on: boolean)
		if on == visible then
			return
		end
		visible = on
		for _, part in parts do
			part.Transparency = if on then 0 else 1
		end
		outline.Enabled = on
	end

	local function place(root: Vector3, direction: Vector3, t: number)
		local flat = Vector3.new(direction.X, 0, direction.Z)
		if flat.Magnitude < 1e-3 then
			return
		end
		flat = flat.Unit
		local push = (math.sin(t * 5) * 0.5 + 0.5) * NUDGE
		local position = root
			+ flat * (DISTANCE + push)
			+ Vector3.new(0, HEIGHT + math.sin(t * 2.4) * BOB, 0)
		local frame = CFrame.lookAt(position, position + flat)
		for _, part in parts do
			part.CFrame = frame * (part:GetAttribute("Desfase") :: CFrame)
		end
	end

	show(false)
	return { place = place, show = show }
end

return GuideArrow
