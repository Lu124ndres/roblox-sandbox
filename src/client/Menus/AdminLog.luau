--!strict
--[[
	AdminLog

	Pestañas de información del panel admin (AdminPanel las arma):
		servers  botón Actualizar ("g:servers"): cada servidor del juego con sus
		         jugadores, el monstruo, el evento y cuántos minutos lleva
		         (Notice "adminServers", Admin/AdminGlobal)
		log      lo que mandaste en esta sesión y lo que respondió el servidor,
		         lo más nuevo arriba
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)

local COLORS = UIConfig.Colors
local CARDS = Style.PALETTE.Cards
local LINE_HEIGHT = 30
local MAX_LINES = 60

export type Log = { frame: Frame, add: (text: string, color: Color3?) -> () }

local AdminLog = {}

local function scroller(parent: Instance, top: number): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, top)
	list.Size = UDim2.new(1, 0, 1, -top)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 8
	list.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	return list
end

local function line(parent: Instance, text: string, color: Color3?, order: number): TextLabel
	local label = Style.text(parent, "Linea", 20, color, 1.5)
	label.LayoutOrder = order
	label.Size = UDim2.new(1, -12, 0, LINE_HEIGHT)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	return label
end

local function page(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Visible = false
	frame.Parent = parent
	return frame
end

function AdminLog.log(parent: Instance): Log
	local frame = page(parent)
	local title = Style.text(frame, "Titulo", 24, COLORS.Coins, 2)
	title.Size = UDim2.new(1, 0, 0, 32)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Registro de esta sesión"
	local list = scroller(frame, 40)
	local order = 0
	local function add(text: string, color: Color3?)
		order -= 1 -- lo más nuevo arriba
		line(list, `{os.date("%H:%M:%S")}  {text}`, color, order)
		local labels = {}
		for _, child in list:GetChildren() do
			if child:IsA("TextLabel") then
				table.insert(labels, child)
			end
		end
		if #labels > MAX_LINES then
			table.sort(labels, function(a, b)
				return a.LayoutOrder > b.LayoutOrder
			end)
			labels[#labels]:Destroy()
		end
	end
	return { frame = frame, add = add }
end

function AdminLog.servers(parent: Instance, send: (name: string, value: any) -> ()): Frame
	local frame = page(parent)
	local refresh = Style.button(frame, "Actualizar", CARDS.Blue, "Actualizar")
	refresh.Size = UDim2.fromOffset(200, 40)
	local status = Style.text(frame, "Estado", 20, COLORS.TextMuted, 1.5)
	status.Position = UDim2.fromOffset(212, 0)
	status.Size = UDim2.new(1, -212, 0, 40)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = "Pregunta a todos los servidores del juego"
	local list = scroller(frame, 50)
	refresh.Activated:Connect(function()
		status.Text = "Preguntando..."
		send("g:servers", 0)
	end)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	notice.OnClientEvent:Connect(function(kind: unknown, servers: unknown)
		if kind ~= "adminServers" or type(servers) ~= "table" then
			return
		end
		for _, child in list:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local players = 0
		for index, server in servers :: { any } do
			players += tonumber(server.players) or 0
			local event = if server.event ~= "" then `  ·  {server.event}` else ""
			line(
				list,
				`{server.job}  ·  {server.players} jugadores  ·  {server.giant}{event}  ·  {server.minutes} min`,
				nil,
				index
			)
		end
		status.Text = `{#(servers :: { any })} servidores, {players} jugadores`
	end)
	return frame
end

return table.freeze(AdminLog)
