--!strict
--[[
	FishDexTabs

	Columna de secciones del Índice de peces (FishDex), a la izquierda: Todos
	y una por rareza (Común ... Mítico). Cada sección es una placa de piedra
	volcánica con su medallón pintado en Canva (Interface/Icons, hoja 4), el
	nombre del color de su rareza, cuántas especies llevas ("1/2") y la
	suerte que da completarla (trébol y "+15%"; en verde si ya está).
	La elegida lleva canto dorado y piedra clara; las demás, piedra oscura.
	Si no caben, la columna se desliza.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionLuck = require(ReplicatedStorage.Shared.CollectionLuck)
local Config = require(ReplicatedStorage.Shared.Config)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local ROW_HEIGHT = 58
local ALL = "Todos"
local DIM = Color3.fromRGB(150, 150, 150) -- la piedra de las no elegidas
local EDGE = Color3.fromRGB(255, 200, 80) -- canto dorado de la elegida
local DONE = UIConfig.Colors.Success

export type Tabs = {
	-- Por id de rareza (y ALL): descubiertos y total.
	counts: (found: { [string]: number }, total: { [string]: number }) -> (),
}

type Entry = {
	id: string,
	button: TextButton,
	count: TextLabel,
	luck: TextLabel?,
	skin: ImageLabel,
	edge: UIStroke,
}

local FishDexTabs = {}

FishDexTabs.ALL = ALL

-- Ícono de la sección: el libro para Todos y el medallón de cada rareza.
function FishDexTabs.icon(id: string): string
	return if id == ALL then "dex" else `dex{id}`
end

-- `onSelect(id)`: id de rareza, o FishDexTabs.ALL para ver todos.
function FishDexTabs.mount(parent: Instance, width: number, onSelect: (id: string) -> ()): Tabs
	local column = Instance.new("ScrollingFrame")
	column.Name = "Secciones"
	column.BackgroundTransparency = 1
	column.BorderSizePixel = 0
	column.Size = UDim2.new(0, width, 1, 0)
	column.ScrollingDirection = Enum.ScrollingDirection.Y
	column.ScrollBarThickness = 4
	column.AutomaticCanvasSize = Enum.AutomaticSize.Y
	column.CanvasSize = UDim2.new()
	column.Parent = parent
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = column
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = column

	local entries: { Entry } = {}
	local selected = ALL
	local function paint()
		for _, entry in entries do
			local on = entry.id == selected
			Kit.tint(entry.skin, if on then Color3.new(1, 1, 1) else DIM)
			entry.edge.Enabled = on
		end
	end
	local function add(id: string, name: string, color: Color3, order: number)
		local button = Instance.new("TextButton")
		button.Name = `Seccion{order}`
		button.Text = ""
		button.AutoButtonColor = false
		button.LayoutOrder = order
		button.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
		local skin = Kit.skin(button, "panel")
		skin.SliceScale = 0.3
		Kit.press(button, skin)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button
		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = EDGE
		edge.Thickness = 3
		edge.Parent = button
		local icon = Icons.view(button, FishDexTabs.icon(id))
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 6, 0.5, 0)
		icon.Size = UDim2.fromOffset(44, 44)
		icon.ZIndex = 2
		local title = Style.text(button, "Nombre", 22, color, 2)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Position = UDim2.fromOffset(56, 6)
		title.Size = UDim2.new(1, -62, 0, 24)
		title.Text = name
		local count = Style.text(button, "Cuenta", 18, nil, 1.5)
		count.TextXAlignment = Enum.TextXAlignment.Left
		count.Position = UDim2.fromOffset(56, 31)
		count.Size = UDim2.new(0.4, 0, 0, 20)
		local luck: TextLabel? = nil
		if CollectionLuck.value(id) > 0 then
			local clover = Icons.view(button, "luck")
			clover.AnchorPoint = Vector2.new(1, 0)
			clover.Position = UDim2.new(1, -54, 0, 30)
			clover.Size = UDim2.fromOffset(22, 22)
			local text = Style.text(button, "Suerte", 18, nil, 1.5)
			text.TextXAlignment = Enum.TextXAlignment.Left
			text.AnchorPoint = Vector2.new(1, 0)
			text.Position = UDim2.new(1, -4, 0, 31)
			text.Size = UDim2.fromOffset(50, 20)
			luck = text
		end
		button.Activated:Connect(function()
			selected = id
			paint()
			onSelect(id)
		end)
		button.Parent = column
		table.insert(entries, {
			id = id,
			button = button,
			count = count,
			luck = luck,
			skin = skin,
			edge = edge,
		})
	end
	add(ALL, ALL, UIConfig.Colors.Fishing, 0)
	for index, rarity in Config.Economy.rarities do
		add(
			rarity.id,
			rarity.displayName,
			UIConfig.RarityColors[rarity.id] or UIConfig.Colors.Fishing,
			index
		)
	end
	paint()

	local function counts(found: { [string]: number }, total: { [string]: number })
		for _, entry in entries do
			local have, all = found[entry.id] or 0, total[entry.id] or 0
			entry.count.Text = `{have}/{all}`
			local luck = entry.luck
			if luck then
				local complete = all > 0 and have >= all
				luck.Text = `+{math.round(CollectionLuck.value(entry.id) * 100)}%`
				luck.TextColor3 = if complete then DONE else UIConfig.Colors.Text
				entry.count.TextColor3 = if complete then DONE else UIConfig.Colors.Text
			end
		end
	end
	return { counts = counts }
end

return FishDexTabs
