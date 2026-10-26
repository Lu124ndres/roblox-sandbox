--!strict
--[[
	AdminRows

	Páginas del panel admin: secciones con título (y una nota debajo) y filas
	"nombre | botones". Los botones van en una grilla de 4 columnas iguales que
	salta de renglón sola, así nada se sale del panel y todos quedan del mismo
	tamaño. Una fila puede tener una casilla para escribir un número o un texto
	(la usan los botones sin valor propio). Cada página tiene el color de su
	alcance (jugador, este servidor, todos) para los botones sin color propio.
	Los botones `confirm` piden un segundo toque ("¿Seguro?").
	Los botones con `run` no mandan nada al servidor: hacen algo en este
	cliente (volar, sin colisión) y su texto lo da `label` (se relee solo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)

local CARDS = Style.PALETTE.Cards
local CELL_HEIGHT = 40
local NAME_WIDTH = 170
local COLUMNS = 4
local GAP = 8
local CONFIRM_SECONDS = 3
local LABEL_SECONDS = 0.5

export type Button = {
	text: string,
	name: string, -- orden (AdminCommands)
	value: any?, -- sin valor: el número de la casilla de la fila
	color: Color3?,
	confirm: boolean?,
	run: (() -> ())?, -- en vez de mandar la orden, esto en el cliente
	label: (() -> string)?, -- texto que cambia (con `run`)
	suffix: boolean?, -- manda "valor:casilla" si la casilla tiene algo (ej. "Frenesi:30")
}
export type Page = {
	frame: ScrollingFrame,
	section: (title: string, note: string?) -> (),
	-- input: texto de ayuda de la casilla; asText: la casilla manda texto en vez de número.
	row: (title: string, buttons: { Button }, input: string?, asText: boolean?) -> (),
}

local AdminRows = {}

local function readNumber(box: TextBox?): number?
	return if box then tonumber((string.gsub(box.Text, "[,%s]", ""))) else nil
end

local function readValue(box: TextBox?, asText: boolean?): any
	if box and asText then
		return box.Text
	end
	return readNumber(box)
end

local function inputCell(parent: Instance, hint: string): TextBox
	local box = Instance.new("TextBox")
	box.Name = "Casilla"
	box.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	box.TextColor3 = Color3.fromRGB(20, 20, 30)
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 165)
	box.PlaceholderText = hint
	box.Text = ""
	box.TextScaled = true
	box.ClearTextOnFocus = false
	box.FontFace = UIConfig.Fonts.Title
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 22
	limit.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	padding.Parent = box
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = box
	Style.border(box, 2)
	box.Parent = parent
	return box
end

-- `send(nombre, valor)` manda la orden (AdminPanel le agrega el jugador elegido).
-- `color`: el de los botones sin color propio (el alcance de la página).
function AdminRows.page(
	parent: Instance,
	send: (name: string, value: any) -> (),
	color: Color3?
): Page
	local frame = Instance.new("ScrollingFrame")
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.CanvasSize = UDim2.new()
	frame.ScrollBarThickness = 8
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.Visible = false
	frame.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	local order = 0

	local function section(title: string, note: string?)
		order += 1
		local label = Style.text(frame, "Seccion", 26, UIConfig.Colors.Coins, 2.5)
		label.LayoutOrder = order
		label.Size = UDim2.new(1, -16, 0, 32)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = title
		if note then
			order += 1
			local hint = Style.text(frame, "Nota", 18, UIConfig.Colors.TextMuted, 1.5)
			hint.LayoutOrder = order
			hint.Size = UDim2.new(1, -16, 0, 20)
			hint.TextXAlignment = Enum.TextXAlignment.Left
			hint.Text = note
		end
	end

	local function row(title: string, buttons: { Button }, input: string?, asText: boolean?)
		order += 1
		local line = Instance.new("Frame")
		line.Name = title
		line.BackgroundTransparency = 1
		line.LayoutOrder = order
		line.Size = UDim2.new(1, -16, 0, 0)
		line.AutomaticSize = Enum.AutomaticSize.Y
		line.Parent = frame
		local name = Style.text(line, "Nombre", 22, nil, 2)
		name.Text = title
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Size = UDim2.fromOffset(NAME_WIDTH - 10, CELL_HEIGHT)
		local cells = Instance.new("Frame")
		cells.Name = "Botones"
		cells.BackgroundTransparency = 1
		cells.Position = UDim2.fromOffset(NAME_WIDTH, 0)
		cells.Size = UDim2.new(1, -NAME_WIDTH, 0, 0)
		cells.AutomaticSize = Enum.AutomaticSize.Y
		cells.Parent = line
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.fromOffset(GAP, GAP)
		grid.CellSize = UDim2.new(1 / COLUMNS, -GAP * (COLUMNS - 1) / COLUMNS, 0, CELL_HEIGHT)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = cells
		local box = if input then inputCell(cells, input) else nil
		for index, spec in buttons do
			local tint = spec.color or color or CARDS.Blue
			local button = Style.button(cells, spec.name, tint, spec.text)
			button.LayoutOrder = index
			local label = button:FindFirstChild("Texto") :: TextLabel
			local run, read = spec.run, spec.label
			if run then
				button.Activated:Connect(function()
					run()
					label.Text = if read then read() else spec.text
				end)
				if read then
					task.spawn(function() -- al reaparecer se apagan solos (AdminMoves)
						while button.Parent do
							if frame.Visible then
								label.Text = read()
							end
							task.wait(LABEL_SECONDS)
						end
					end)
				end
				continue
			end
			local armedUntil = 0
			button.Activated:Connect(function()
				if spec.confirm and os.clock() > armedUntil then
					armedUntil = os.clock() + CONFIRM_SECONDS
					label.Text = "¿Seguro?"
					task.delay(CONFIRM_SECONDS, function()
						label.Text = spec.text
					end)
					return
				end
				armedUntil = 0
				label.Text = spec.text
				local value = spec.value
				if value == nil then
					value = readValue(box, asText)
				elseif spec.suffix and box and box.Text ~= "" then
					value = `{value}:{box.Text}`
				end
				send(spec.name, value)
			end)
		end
	end

	return { frame = frame, section = section, row = row }
end

return table.freeze(AdminRows)
