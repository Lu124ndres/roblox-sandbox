--!strict
--[[
	FishDexCard

	Una casilla de la colección (FishDex): piedra teñida del color de su
	rareza (un hueco oscuro en la piedra si falta descubrirlo), el
	pez en 3D dentro de un ViewportFrame (o su silueta con el candado de Canva), el
	nombre y la rareza con la cantidad pescada. El giro lo hace FishDex,
	solo con la ventana abierta, con el model que devuelve build.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local CARDS = Style.PALETTE.Cards
-- Silueta plana (luz ambiente blanca, sin sol), un poco más clara que el fondo del hueco.
local SILHOUETTE = Color3.fromRGB(64, 70, 88)
-- Color de la tarjeta por rareza (los de UIConfig.RarityColors son para texto).
local CARD_COLORS: { [string]: Color3 } = {
	Comun = Color3.fromRGB(120, 132, 156),
	PocoComun = CARDS.Green,
	Raro = CARDS.Blue,
	Epico = CARDS.Purple,
	Legendario = CARDS.Yellow,
	Mitico = CARDS.Pink,
}

export type Card = { box: Frame, model: Model?, info: TextLabel, known: boolean, order: number }

local FishDexCard = {}

function FishDexCard.infoText(fishId: string, amount: number): string
	local rarity = FishCatalog.rarity(fishId)
	return if amount > 0
		then `{rarity.displayName} · x{NumberFormat.short(amount)}`
		else rarity.displayName
end

local function silhouette(model: Model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = SILHOUETTE
			part.Material = Enum.Material.SmoothPlastic
		elseif part:IsA("ParticleEmitter") or part:IsA("Light") then
			part:Destroy()
		end
	end
end

function FishDexCard.build(parent: Instance, fishId: string, amount: number, order: number): Card
	local fish = FishCatalog.get(fishId)
	local rarity = FishCatalog.rarity(fishId)
	local known = amount > 0
	-- Descubierto: casilla volcánica con un toque del color de su rareza (como las
	-- tarjetas de MEJORAS). Sin descubrir: un hueco vacío en la piedra.
	local box = Instance.new("Frame")
	box.Name = `Pez{order}`
	box.LayoutOrder = order
	box.Parent = parent
	if known then
		local color = CARD_COLORS[rarity.id] or CARDS.Blue
		Kit.skin(box, "casilla", color:Lerp(Color3.new(1, 1, 1), 0.45))
	else
		Kit.skin(box, "hondo")
	end

	local view = Instance.new("ViewportFrame")
	view.BackgroundTransparency = 1
	view.Position = UDim2.fromScale(0.04, 0.04)
	view.Size = UDim2.fromScale(0.92, 0.58)
	view.Ambient = if known then Color3.fromRGB(200, 200, 210) else Color3.new(1, 1, 1)
	view.LightColor = if known then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	view.Parent = box
	local world = Instance.new("WorldModel")
	world.Parent = view
	local model = FishModel.build(fishId, 1)
	if not known then
		silhouette(model)
	end
	model.Parent = world
	-- Lejos según el largo del pez: los alargados (pez espada) caben enteros.
	local extent = model:GetExtentsSize().Magnitude
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(extent * 1.6, extent * 0.38, 0), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera
	if not known then
		local lock = Icons.view(box, "lock")
		lock.Name = "Candado"
		lock.AnchorPoint = Vector2.new(0.5, 0.5)
		lock.Position = UDim2.fromScale(0.5, 0.33)
		lock.Size = UDim2.fromScale(0.36, 0.36)
		local square = Instance.new("UIAspectRatioConstraint")
		square.Parent = lock
		lock.ZIndex = 3
	end

	local name = Style.text(box, "Nombre", 22, nil, 2.5)
	name.Text = if known and fish then fish.displayName else "???"
	if not known then
		Kit.gold(name)
	end
	name.Position = UDim2.fromScale(0.04, 0.63)
	name.Size = UDim2.fromScale(0.92, 0.17)
	local info = Style.text(box, "Info", 17, nil, 2)
	info.Text = FishDexCard.infoText(fishId, amount)
	info.Position = UDim2.fromScale(0.04, 0.81)
	info.Size = UDim2.fromScale(0.92, 0.14)
	return {
		box = box,
		model = if known then model else nil,
		info = info,
		known = known,
		order = order,
	}
end

return FishDexCard
