--!strict
--[[
	ShareLine

	Fila de aportes debajo del panel del monstruo (mientras come), en una
	ranura de piedra: a la
	izquierda tu aporte ("Tú: 12%") y a la derecha los 3 que más aportaron
	con medalla ("🥇 Ana 40%  🥈 Leo 20%  🥉 Sam 9%"). Competencia sana:
	todos ven quién está empujando más. Lee lo que publica el servidor
	(Feeding/Contributions): atributo TopAportes del gigante y Aporte del
	jugador.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Kit = require(script.Parent.Kit)
local Style = require(script.Parent.Style)

local MEDALS = { "🥇", "🥈", "🥉" }
local ROW_HEIGHT = 22
local INSET = 8 -- margen del texto dentro de la ranura de piedra

local ShareLine = {}

local function percent(share: number): string
	if share <= 0 then
		return "0%"
	end
	return if share < 0.01 then "<1%" else `{math.floor(share * 100)}%`
end

function ShareLine.mount(panel: Frame)
	local player = Players.LocalPlayer
	local state = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local row = Instance.new("Frame")
	row.Name = "Aportes"
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 0, 1, 2)
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	row.Visible = false
	row.Parent = panel
	Kit.skin(row, "hondo").SliceScale = 0.22 -- ranura fina tallada bajo el panel
	local mine = Style.text(row, "Tu", 18, nil, 2)
	mine.TextXAlignment = Enum.TextXAlignment.Left
	mine.Position = UDim2.fromOffset(INSET, 2)
	mine.Size = UDim2.new(0.28, -INSET, 1, -4)
	Kit.gold(mine)
	local top = Style.text(row, "Top", 18, nil, 2)
	top.TextXAlignment = Enum.TextXAlignment.Right
	top.AnchorPoint = Vector2.new(1, 0)
	top.Position = UDim2.new(1, -INSET, 0, 2)
	top.Size = UDim2.new(0.72, -INSET, 1, -4)

	local function refresh()
		local raw = state:GetAttribute(Protocol.GiantAttributes.TopShares)
		local ok, list =
			pcall(HttpService.JSONDecode, HttpService, if type(raw) == "string" then raw else "[]")
		local feeding = state:GetAttribute(Protocol.GiantAttributes.Phase) == "feeding"
		local entries = if ok and type(list) == "table" then list else {}
		row.Visible = feeding and #entries > 0
		local parts = {}
		for index, entry in entries do
			if
				type(entry) == "table"
				and type(entry.n) == "string"
				and type(entry.s) == "number"
			then
				table.insert(parts, `{MEDALS[index] or ""} {entry.n} {percent(entry.s)}`)
			end
		end
		top.Text = table.concat(parts, "  ")
		local share = player:GetAttribute(Protocol.PlayerAttributes.Share)
		mine.Text = `Tú: {percent(if type(share) == "number" then share else 0)}`
	end
	state:GetAttributeChangedSignal(Protocol.GiantAttributes.TopShares):Connect(refresh)
	state:GetAttributeChangedSignal(Protocol.GiantAttributes.Phase):Connect(refresh)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.Share):Connect(refresh)
	refresh()
end

return ShareLine
