--!strict
--[[
	RankingBoards

	Dibuja el ranking global en los tableros del salón de la fama de la entrada
	(TableroPoder, TableroKills y TableroRenacimientos del mapa) con lo que publica el servidor en
	ReplicatedStorage.Rankings (Leaderboards): top 10 con nombre y valor.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

local BOARDS =
	{ Poder = "TableroPoder", Kills = "TableroKills", Renacimientos = "TableroRenacimientos" }
local MEDALS =
	{ Color3.fromRGB(255, 205, 60), Color3.fromRGB(210, 220, 230), Color3.fromRGB(220, 150, 90) }

local RankingBoards = {}

local function surface(part: BasePart): Frame
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- mira hacia la aparición (como los carteles)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = part
	local list = Instance.new("Frame")
	list.BackgroundColor3 = Color3.fromRGB(20, 30, 44)
	list.Size = UDim2.fromScale(1, 1)
	list.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingLeft, padding.PaddingRight =
		UDim.new(0, 12), UDim.new(0, 16), UDim.new(0, 16)
	padding.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list
	return list
end

local function render(list: Frame, json: unknown)
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local ok, entries = pcall(function()
		return if type(json) == "string" then HttpService:JSONDecode(json) else {}
	end)
	local entryList = (if ok and type(entries) == "table" then entries else {}) :: { any }
	if #entryList == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0.12, 0)
		empty.TextScaled = true
		empty.FontFace = UIConfig.Fonts.Title
		empty.TextColor3 = UIConfig.Colors.TextMuted
		empty.Text = "Cargando ranking..."
		empty.Parent = list
	end
	for index, entry in entryList do
		local row = Instance.new("TextLabel")
		row.LayoutOrder = index
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0.088, 0)
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.FontFace = UIConfig.Fonts.Title
		row.TextColor3 = MEDALS[index] or UIConfig.Colors.Text
		row.Text =
			`{index}. {tostring(entry.name)}  —  {NumberFormat.short(tonumber(entry.value) or 0)}`
		row.Parent = list
	end
end

function RankingBoards.start()
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local rankings = ReplicatedStorage:WaitForChild("Rankings")
	for board, partName in BOARDS do
		local part = map:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			local list = surface(part)
			local function update()
				render(list, rankings:GetAttribute(board))
			end
			rankings:GetAttributeChangedSignal(board):Connect(update)
			update()
		end
	end
end

return RankingBoards
