--!strict
--[[
	BlockVolcano

	El volcán de bloques: una montaña cerrada con copa de lava, la cueva del gigante
	adentro y el arco al pie como única entrada, con un túnel hasta el paseo
	(tools/blender/volcan_*.py; pedido del usuario, docs/decisiones.md). Las mallas viven
	en ServerStorage.VolcanBloques (en el .rbxl, ya en su lugar) y al arrancar se copian a
	Workspace.VolcanBloques:
		Volcan_*           la montaña por fuera (se choca)
		VolcanCueva_*      paredes, techo y piso de la cueva y del túnel (se choca)
		VolcanLava         la copa de lava y las coladas de afuera (Neon)
		VolcanCuevaLava    las vetas y ríos de lava de la cueva (Neon)
	El lago sigue siendo terreno (TerrainBuilder: lo llenan el agua, la arena, la ceniza y
	el hielo). La cueva no recibe sol: la alumbran luces de lava alrededor del paseo, sobre
	el lago y a lo largo del túnel.
		present() -> boolean
		place()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local SOURCE = Protocol.Map.BlockVolcano -- en ServerStorage, y la copia en Workspace
local LAVA = { VolcanLava = true, VolcanCuevaLava = true }
local LAVA_COLOR = Color3.fromRGB(255, 132, 36)
local LIGHT_COLOR = Color3.fromRGB(255, 150, 80)

-- Luces de la cueva: (cuántas, a qué radio del centro, a qué alto sobre el paseo, alcance, brillo).
type Ring = { count: number, radius: number, rise: number, range: number, brightness: number }
local RINGS: { Ring } = {
	{ count = 12, radius = 214, rise = 26, range = 60, brightness = 2.2 }, -- sobre el paseo
	{ count = 6, radius = 120, rise = 60, range = 60, brightness = 1.6 }, -- sobre el lago
}
local TUNNEL_LIGHT_STEP = 44 -- studs entre luces del túnel
local TUNNEL_LIGHT_RISE = 26
local TUNNEL_LIGHT = { range = 40, brightness = 1.8 }

local BlockVolcano = {}

function BlockVolcano.present(): boolean
	return ServerStorage:FindFirstChild(SOURCE) ~= nil
end

local function light(holder: BasePart, position: Vector3, range: number, brightness: number)
	local attachment = Instance.new("Attachment")
	attachment.Name = "LuzLava"
	attachment.WorldPosition = position
	attachment.Parent = holder
	local point = Instance.new("PointLight")
	point.Color = LIGHT_COLOR
	point.Range = range
	point.Brightness = brightness
	point.Shadows = false
	point.Parent = attachment
end

-- Una pieza invisible que sostiene las luces de la cueva y del túnel.
local function lights(model: Model)
	local center = WorldZones.craterCenter + Vector3.new(0, L.craterRimHeight, 0)
	local holder = Instance.new("Part")
	holder.Name = "Luces"
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = CFrame.new(center)
	holder.Parent = model
	for _, ring in RINGS do
		for k = 1, ring.count do
			local angle = 2 * math.pi * (k - 0.5) / ring.count
			local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * ring.radius
			light(
				holder,
				center + offset + Vector3.new(0, ring.rise, 0),
				ring.range,
				ring.brightness
			)
		end
	end
	local door = WorldZones.craterDoor()
	local _, gate = WorldZones.bridgeEnds()
	local along = gate - door
	local steps = math.floor(along.Magnitude / TUNNEL_LIGHT_STEP)
	for k = 0, steps do
		local position = door
			+ along * (k / math.max(steps, 1))
			+ Vector3.new(0, TUNNEL_LIGHT_RISE, 0)
		light(holder, position, TUNNEL_LIGHT.range, TUNNEL_LIGHT.brightness)
	end
end

function BlockVolcano.place()
	local source = ServerStorage:FindFirstChild(SOURCE)
	if not source then
		return
	end
	local model = Instance.new("Model")
	model.Name = SOURCE
	-- Siempre cargado aunque el lugar use streaming: la montaña se ve desde toda la isla.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local count = 0
	for _, item in source:GetDescendants() do
		if not item:IsA("MeshPart") then
			continue
		end
		local part = item:Clone()
		part.Anchored = true
		part.CanCollide, part.CanQuery, part.CanTouch = true, true, false
		if LAVA[part.Name] then
			part.Material = Enum.Material.Neon
			part.Color = LAVA_COLOR
			part.CastShadow = false
		end
		part.Parent = model
		count += 1
	end
	lights(model)
	model.Parent = Workspace
	print(`BlockVolcano: volcán de bloques con {count} mallas`)
end

return table.freeze(BlockVolcano)
