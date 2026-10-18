--!strict
--[[
	RankingBoards

	Dibuja el ranking global en los tableros del salón de la fama de la entrada
	(TableroPoder, TableroKills y TableroRenacimientos del mapa) con lo que publica el servidor en
	ReplicatedStorage.Rankings (Leaderboards): top 10 con nombre y valor. Se dibujan
	por la cara que mira hacia adentro, hacia la zona de entrenamiento.

	Estilo de la interfaz (Interface/Kit): una placa de piedra volcánica con cada
	puesto en un hueco tallado; el 1, 2 y 3 en oro, plata y bronce, el resto en
	blanco cálido, y el valor en dorado. Es un cartel del mundo: letras grandes con
	contorno marrón grueso para leerse de lejos. Los tableros más anchos que altos
	(el de renacimientos, sobre el arco) reparten los diez puestos en dos columnas.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Parent.Interface.Kit)

local BOARDS =
	{ Poder = "TableroPoder", Kills = "TableroKills", Renacimientos = "TableroRenacimientos" }
local MEDALS =
	{ Color3.fromRGB(255, 205, 60), Color3.fromRGB(210, 220, 230), Color3.fromRGB(220, 150, 90) }
local WARM_WHITE = Color3.fromRGB(255, 238, 212)
local MUTED = Color3.fromRGB(196, 176, 150)
local ROWS = 10 -- el servidor publica el top 10
local MIN_ROWS = 5 -- con pocos jugadores, los puestos se agrandan hasta este alto
local PIXELS_PER_STUD = 40
local FRAME_SLICE = 1 -- canto de la placa: ~1 stud a 40 píxeles por stud
local HOLE_SLICE = 0.6
local INSET = 52 -- píxeles del canto de la placa al contenido
local GAP = 6
local OUTLINE = 4 -- contorno de las letras, en píxeles de la superficie

local RankingBoards = {}

type Board = { list: Frame, empty: TextLabel, grid: UIGridLayout, columns: number }

-- Texto que escala al alto de su caja, con contorno marrón oscuro grueso.
local function text(parent: Instance, name: string, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = UIConfig.Fonts.Title
	label.TextColor3 = color
	label.TextScaled = true
	label.ZIndex = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = Kit.GOLD_OUTLINE
	stroke.Thickness = OUTLINE
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function surface(part: BasePart): Board
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front -- mira al centro de la isla: se lee desde el entrenamiento
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0.15 -- la piedra ya es oscura: que la sombra no la apague
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = part
	local plate = Instance.new("Frame")
	plate.Name = "Placa"
	plate.Size = UDim2.fromScale(1, 1)
	plate.Parent = gui
	Kit.skin(plate, "panel").SliceScale = FRAME_SLICE

	local list = Instance.new("Frame")
	list.Name = "Lista"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(INSET, INSET - 8)
	list.Size = UDim2.new(1, -INSET * 2, 1, -(INSET - 8) * 2)
	list.ZIndex = 1
	list.Parent = plate
	-- Una columna en los tableros altos; dos (1-5 y 6-10) en los anchos.
	local columns = if part.Size.X > part.Size.Y * 1.5 then 2 else 1
	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirection = Enum.FillDirection.Vertical
	grid.CellPadding = UDim2.fromOffset(GAP * 3, GAP)
	grid.Parent = list

	local empty = text(plate, "Cargando", MUTED)
	empty.AnchorPoint = Vector2.new(0.5, 0.5)
	empty.Position = UDim2.fromScale(0.5, 0.5)
	empty.Size = UDim2.new(1, -INSET * 2, 0.14, 0)
	empty.Text = "Cargando ranking..."
	return { list = list, empty = empty, grid = grid, columns = columns }
end

-- Un puesto: hueco tallado con el número, el nombre y el valor.
local function row(list: Frame, index: number, name: string, value: number)
	local frame = Instance.new("Frame")
	frame.Name = `Puesto{index}`
	frame.LayoutOrder = index
	frame.Parent = list
	Kit.skin(frame, "hondo").SliceScale = HOLE_SLICE
	local color = MEDALS[index] or WARM_WHITE
	local rank = text(frame, "Puesto", color)
	rank.Position = UDim2.fromScale(0.02, 0.12)
	rank.Size = UDim2.fromScale(0.12, 0.76)
	rank.Text = `{index}`
	local player = text(frame, "Nombre", color)
	player.TextXAlignment = Enum.TextXAlignment.Left
	player.Position = UDim2.fromScale(0.16, 0.14)
	player.Size = UDim2.fromScale(0.52, 0.72)
	player.Text = name
	local amount = text(frame, "Valor", WARM_WHITE)
	amount.TextXAlignment = Enum.TextXAlignment.Right
	amount.Position = UDim2.fromScale(0.7, 0.14)
	amount.Size = UDim2.fromScale(0.27, 0.72)
	amount.Text = NumberFormat.short(value)
	Kit.gold(amount)
end

local function render(board: Board, json: unknown)
	for _, child in board.list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local ok, entries = pcall(function()
		return if type(json) == "string" then HttpService:JSONDecode(json) else {}
	end)
	local entryList = (if ok and type(entries) == "table" then entries else {}) :: { any }
	-- Las filas toman el alto de los puestos que hay (al menos MIN_ROWS): con pocos
	-- jugadores, letras grandes; con el top 10, todo entra.
	local shown = math.clamp(#entryList, MIN_ROWS, ROWS)
	local perColumn = math.ceil(shown / board.columns)
	board.grid.FillDirectionMaxCells = perColumn
	board.grid.CellSize = UDim2.new(1 / board.columns, -GAP * 3, 1 / perColumn, -GAP)
	board.empty.Visible = #entryList == 0
	for index, entry in entryList do
		row(board.list, index, tostring(entry.name), tonumber(entry.value) or 0)
	end
end

function RankingBoards.start()
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local rankings = ReplicatedStorage:WaitForChild("Rankings")
	for board, partName in BOARDS do
		local part = map:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			local view = surface(part)
			local function update()
				render(view, rankings:GetAttribute(board))
			end
			rankings:GetAttributeChangedSignal(board):Connect(update)
			update()
		end
	end
end

return RankingBoards
