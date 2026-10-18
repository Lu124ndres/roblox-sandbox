--!strict
--[[
	FishDexTabs

	Pestañas de la colección de peces por categoría (rareza): Todos, Común,
	Poco común, Raro, Épico, Legendario y Mítico, cada una con su color y
	cuántos llevas de esa categoría ("Raro 2/5"). La elegida se ve encendida
	y un poco más grande; las demás, apagadas. Si no caben, se deslizan.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)

local TAB_HEIGHT = 40 -- la piedra tallada pide algo más de alto que la pestaña plana
local ALL = "Todos"

export type Tabs = {
	height: number,
	-- Por id de rareza (y ALL): descubiertos y total.
	counts: (found: { [string]: number }, total: { [string]: number }) -> (),
}

type Entry = {
	id: string,
	name: string,
	color: Color3,
	button: TextButton,
	label: TextLabel,
	scale: UIScale,
}

local FishDexTabs = {}

FishDexTabs.ALL = ALL

-- `onSelect(id)`: id de rareza, o FishDexTabs.ALL para ver todos.
function FishDexTabs.mount(parent: Instance, top: number, onSelect: (id: string) -> ()): Tabs
	local row = Instance.new("ScrollingFrame")
	row.Name = "Categorias"
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Position = UDim2.fromOffset(0, top)
	row.Size = UDim2.new(1, 0, 0, TAB_HEIGHT + 6)
	row.ScrollingDirection = Enum.ScrollingDirection.X
	row.ScrollBarThickness = 0
	row.AutomaticCanvasSize = Enum.AutomaticSize.X
	row.CanvasSize = UDim2.new()
	row.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = row
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = row

	local entries: { Entry } = {}
	local selected = ALL
	local function paint()
		for _, entry in entries do
			local on = entry.id == selected
			-- La piedra se tiñe del BackgroundColor3 (Style.button): apagada, más oscura.
			local h, s, v = entry.color:ToHSV()
			entry.button.BackgroundColor3 = if on
				then entry.color
				else Color3.fromHSV(h, s * 0.7, v * 0.5)
			entry.label.TextTransparency = if on then 0 else 0.25
			entry.scale.Scale = if on then 1 else 0.92
		end
	end
	local function add(id: string, name: string, color: Color3, order: number)
		local button = Style.button(row, `Categoria{order}`, color, name)
		button.LayoutOrder = order
		-- Los nombres largos ("Poco común") llevan pestaña más ancha, si no la letra queda chica.
		local width = if id == ALL then 104 else math.max(132, 60 + 10 * (utf8.len(name) or 0))
		button.Size = UDim2.fromOffset(width, TAB_HEIGHT)
		local label = button:FindFirstChild("Texto") :: TextLabel
		local scale = Instance.new("UIScale")
		scale.Parent = button
		button.Activated:Connect(function()
			selected = id
			paint()
			onSelect(id)
		end)
		table.insert(
			entries,
			{ id = id, name = name, color = color, button = button, label = label, scale = scale }
		)
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
			entry.label.Text = `{entry.name} {found[entry.id] or 0}/{total[entry.id] or 0}`
		end
	end
	return { height = TAB_HEIGHT + 6, counts = counts }
end

return FishDexTabs
