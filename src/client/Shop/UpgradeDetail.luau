--!strict
--[[
	UpgradeDetail

	Panel grande de la izquierda en MEJORAS: muestra el nivel elegido en la
	cuadrícula (al abrir, el siguiente por comprar). Va en un hueco de piedra:
	ícono grande sobre piedra y rayos del color de su rareza, nombre dorado,
	qué da comparado con lo que tienes ahora (x2 → x3), una barra de cuánto te
	falta juntar y los botones para comprar: con monedas el de lava (lo
	principal) y con Robux el verde. Solo se compra el siguiente nivel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local GearIcons = require(script.Parent.Parent.Interface.GearIcons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)

local PALETTE = Style.PALETTE
local WHITE = Color3.new(1, 1, 1)
local SOFT = Color3.fromRGB(255, 236, 200)

export type DetailSpec = {
	category: Upgrades.Category,
	level: number,
	def: any,
	currentDef: any, -- lo que tiene equipado ahora
	owned: number,
	count: number, -- niveles de la categoría
	coins: number,
	robux: number?, -- precio en Robux ya calculado (nil = no se vende)
}

export type Detail = { update: (spec: DetailSpec) -> () }

local UpgradeDetail = {}

local function box(parent: Instance, name: string, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

function UpgradeDetail.mount(parent: Instance, onCoins: () -> (), onRobux: () -> ()): Detail
	local panel = box(parent, "Detalle", PALETTE.Panel)
	panel.Size = UDim2.new(0.37, -8, 1, 0)
	Kit.skin(panel, "hondo")

	local status = Style.text(panel, "Estado", 26, nil, 2.5)
	status.Position = UDim2.fromScale(0.05, 0.02)
	status.Size = UDim2.fromScale(0.9, 0.065)
	Kit.gold(status)

	-- Pedestal volcánico detrás del nombre y los datos (oscurecido: el texto va encima).
	local pedestal = Instance.new("ImageLabel")
	pedestal.Name = "Pedestal"
	pedestal.BackgroundTransparency = 1
	pedestal.Image = Assets.UI.PiedraPedestal
	pedestal.ImageColor3 = Color3.fromRGB(150, 150, 150)
	pedestal.ScaleType = Enum.ScaleType.Fit
	pedestal.Position = UDim2.fromScale(0.03, 0.36)
	pedestal.Size = UDim2.fromScale(0.94, 0.62)
	pedestal.Parent = panel

	local art = box(panel, "Arte", WHITE)
	art.ClipsDescendants = true
	art.Position = UDim2.fromScale(0.06, 0.09)
	art.Size = UDim2.fromScale(0.88, 0.36)
	local icon: ImageLabel? = nil
	local levelChip = Style.text(panel, "Nivel", 20, WHITE, 2)
	levelChip.Position = UDim2.fromScale(0.1, 0.1)
	levelChip.Size = UDim2.fromScale(0.4, 0.06)
	levelChip.TextXAlignment = Enum.TextXAlignment.Left
	levelChip.ZIndex = 4

	local name = Style.text(panel, "Nombre", 30, WHITE, 2.5)
	name.Position = UDim2.fromScale(0.04, 0.46)
	name.Size = UDim2.fromScale(0.92, 0.08)
	Kit.gold(name)

	local stats = Instance.new("Frame")
	stats.Name = "Datos"
	stats.BackgroundTransparency = 1
	stats.Position = UDim2.fromScale(0.08, 0.55)
	stats.Size = UDim2.fromScale(0.84, 0.15)
	stats.Parent = panel
	local statList = Instance.new("UIListLayout")
	statList.Padding = UDim.new(0, 2)
	statList.Parent = stats

	local bar = CardParts.bar(panel, PALETTE.Coins, 20)
	bar.track.Position = UDim2.fromScale(0.06, 0.71)
	bar.track.Size = UDim2.fromScale(0.88, 0.065)

	local buttons = Instance.new("Frame")
	buttons.BackgroundTransparency = 1
	buttons.Position = UDim2.fromScale(0.05, 0.8)
	buttons.Size = UDim2.fromScale(0.9, 0.17)
	buttons.Parent = panel
	local coinsButton = ShopParts.price(buttons, PALETTE.Buy, "coins")
	coinsButton.button.Activated:Connect(onCoins)
	-- Comprar con monedas es lo principal: marco de lava (como TIENDA). Se viste
	-- encima de la piedra verde, así que ya no se tiñe al cambiar de color.
	Kit.press(coinsButton.button, Kit.skin(coinsButton.button, "lava"))
	local robuxButton = ShopParts.price(buttons, PALETTE.Buy, "robux")
	robuxButton.button.Activated:Connect(onRobux)
	local note = Style.text(buttons, "Nota", 24, SOFT, 2)
	note.Size = UDim2.fromScale(1, 1)

	local function statRow(text: string, order: number)
		local row = Style.text(stats, "Dato", 24, SOFT, 2)
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0.48, 0)
		row.RichText = true
		row.Text = text
	end

	local function update(spec: DetailSpec)
		local tier = GearIcons.tierColor(spec.category, spec.level)
		for _, child in art:GetChildren() do
			if not child:IsA("UICorner") then
				child:Destroy() -- la piedra, los rayos y el ícono del nivel anterior
			end
		end
		Kit.skin(art, "casilla", tier:Lerp(WHITE, 0.6))
		icon = GearIcons.view(art, spec.category, spec.level)
		local image = icon :: ImageLabel
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.52)
		image.Size = UDim2.fromScale(0.9, 0.9)
		image.ZIndex = 2
		levelChip.Text = `Nivel {spec.level}/{spec.count}`
		name.Text = spec.def.name

		for _, child in stats:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local now = Upgrades.stats(spec.category, spec.currentDef)
		for index, stat in Upgrades.stats(spec.category, spec.def) do
			local before = now[index] and now[index].value
			local compare = spec.level > spec.owned and before ~= nil and before ~= stat.value
			statRow(
				if compare
					then `{stat.label}: {before} → <font color="#7CFF6B">{stat.value}</font>`
					else `{stat.label}: {stat.value}`,
				index
			)
		end

		local isNext = spec.level == spec.owned + 1
		local afford = spec.coins >= spec.def.price
		bar.track.Visible = isNext
		bar.set(
			math.clamp(spec.coins / math.max(spec.def.price, 1), 0.02, 1),
			if afford
				then "¡Te alcanza!"
				else `Te faltan {NumberFormat.short(spec.def.price - spec.coins)}`
		)
		coinsButton.button.Visible = isNext
		robuxButton.button.Visible = isNext and spec.robux ~= nil
		-- Sin monedas sigue verde y responde (el servidor avisa cuánto falta).
		coinsButton.set(NumberFormat.short(spec.def.price), true)
		coinsButton.label.TextColor3 = if afford then WHITE else Color3.fromRGB(255, 190, 190)
		local split = robuxButton.button.Visible
		coinsButton.button.Size = UDim2.fromScale(if split then 0.54 else 1, 1)
		robuxButton.button.Position = UDim2.fromScale(0.58, 0)
		robuxButton.button.Size = UDim2.fromScale(0.42, 1)
		if spec.robux then
			robuxButton.set(tostring(spec.robux), true)
		end
		note.Visible = not isNext
		if spec.level == spec.owned then
			status.Text = if spec.owned == spec.count then "¡NIVEL MÁXIMO!" else "EQUIPADA"
			note.Text = "La estás usando"
		elseif spec.level < spec.owned then
			status.Text, note.Text = "YA LA TIENES", "Tienes una mejor"
		elseif isNext then
			status.Text = "SIGUIENTE MEJORA"
		else
			status.Text, note.Text = "BLOQUEADA", `Compra antes el Nivel {spec.owned + 1}`
		end
	end

	return { update = update }
end

return UpgradeDetail
