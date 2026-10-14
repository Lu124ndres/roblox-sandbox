--!strict
--[[
	UpgradeRow

	Fila de madera de MEJORAS: miniatura (la caña en 3D o el ícono), nombre,
	qué da, "Nivel N" y, según el estado:
		comprada      "Equipada" / "Tienes"
		la siguiente  botón verde con el precio en monedas y botón morado
		              con el precio en Robux (sin juntar monedas)
		las demás     el precio en monedas, apagado
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Device = require(script.Parent.Parent.Interface.Device)
local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local RodPreview = require(script.Parent.RodPreview)

local PALETTE = Style.PALETTE
local ROW_HEIGHT = 96
local BUTTON_HEIGHT = 60 -- botones de precio (se tocan con el dedo)
-- Texto mínimo de "qué da": en táctil la ventana escala ~0.8, así queda en ≥ 14 px.
local EFFECT_MIN_TEXT = 14
local EFFECT_MIN_TEXT_TOUCH = 18
local ICONS: { [string]: string } = { Rod = "rod", Basket = "basket", Boots = "boots" }

export type RowSpec = {
	category: Upgrades.Category,
	index: number,
	def: any,
	owned: number, -- nivel que ya tiene
	coins: number, -- monedas del jugador
	robux: number?, -- precio en Robux de este nivel (nil = no se vende)
	robuxPrice: (key: string, robux: number) -> number,
	onCoins: () -> (),
	onRobux: () -> (),
}

local UpgradeRow = {}

function UpgradeRow.new(parent: Instance, spec: RowSpec)
	local current = spec.index == spec.owned
	local row = Instance.new("Frame")
	row.Name = `Nivel{spec.index}`
	row.LayoutOrder = spec.index
	row.BackgroundColor3 = if spec.index <= spec.owned
		then PALETTE.Wood
		else PALETTE.Wood:Lerp(Color3.new(0, 0, 0), 0.25)
	row.Size = UDim2.new(1, -10, 0, ROW_HEIGHT)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row
	Style.gradient(row, row.BackgroundColor3)
	Style.border(row, if current then 5 else 3)
	if current then
		local glow = row:FindFirstChildOfClass("UIStroke") :: UIStroke
		glow.Color = PALETTE.Coins
	end
	row.Parent = parent

	local slot = Instance.new("Frame")
	slot.Name = "Miniatura"
	slot.BackgroundColor3 = PALETTE.WoodPanel
	slot.Position = UDim2.fromOffset(8, 8)
	slot.Size = UDim2.fromOffset(ROW_HEIGHT - 16, ROW_HEIGHT - 16)
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 12)
	slotCorner.Parent = slot
	Style.border(slot, 2.5)
	slot.Parent = row
	if spec.category == "Rod" then
		RodPreview.attach(slot, spec.index, ROW_HEIGHT - 18)
	else
		local icon = Icons.view(slot, ICONS[spec.category])
		icon.Position = UDim2.fromOffset(4, 4)
		icon.Size = UDim2.new(1, -8, 1, -8)
	end

	local left = ROW_HEIGHT + 2
	local name = Style.text(row, "Nombre", 28, nil, 2.5)
	name.Text = spec.def.name
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Position = UDim2.fromOffset(left, 10)
	name.Size = UDim2.new(0.33, -left + 40, 0, 32) -- termina antes de "Nivel" (0.43)
	local effect = Style.text(row, "Efecto", 20, Color3.fromRGB(255, 236, 200), 2)
	effect.Text = Upgrades.describe(spec.category, spec.def)
	effect.TextXAlignment = Enum.TextXAlignment.Left
	effect.Position = UDim2.fromOffset(left, 44)
	effect.Size = UDim2.new(0.43, -left - 6, 0, 46)
	effect.TextWrapped = true
	local effectLimit = effect:FindFirstChildOfClass("UITextSizeConstraint")
	if effectLimit then
		effectLimit.MinTextSize = if Device.touch() then EFFECT_MIN_TEXT_TOUCH else EFFECT_MIN_TEXT
	end

	local level = Style.text(row, "Nivel", 24, nil, 2.5)
	level.Text = `Nivel {spec.index}`
	level.AnchorPoint = Vector2.new(0.5, 0.5)
	level.Position = UDim2.fromScale(0.5, 0.5)
	level.Size = UDim2.new(0.14, 0, 0, 30)

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Position = UDim2.new(1, -10, 0.5, 0)
	holder.Size = UDim2.new(0.38, 0, 0, BUTTON_HEIGHT)
	holder.Parent = row
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = holder

	if spec.index <= spec.owned then
		local owned = Style.text(holder, "Estado", 28, PALETTE.Buy, 3)
		owned.Text = if current then "Equipada" else "Tienes"
		owned.Size = UDim2.fromScale(1, 1)
		return
	end
	local isNext = spec.index == spec.owned + 1
	local coins = ShopParts.price(holder, PALETTE.Buy, "coins")
	coins.button.Size = UDim2.fromScale(if isNext and spec.robux then 0.5 else 0.6, 1)
	coins.set(NumberFormat.short(spec.def.price), isNext)
	if isNext and spec.coins < spec.def.price then
		coins.label.TextColor3 = Color3.fromRGB(255, 200, 200)
	end
	coins.button.Activated:Connect(function()
		if isNext then
			spec.onCoins()
		end
	end)
	if isNext and spec.robux then
		local robux = ShopParts.price(holder, PALETTE.RobuxAlt, "robux")
		robux.button.Size = UDim2.fromScale(0.46, 1)
		robux.set(tostring(spec.robuxPrice(`{spec.category}{spec.index}`, spec.robux)), true)
		robux.button.Activated:Connect(spec.onRobux)
	end
end

return UpgradeRow
