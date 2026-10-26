--!strict
--[[
	AdminPanel

	Panel de los administradores (atributo EsAdmin, lo pone el servidor; nadie
	más ve el botón). Rehecho el 2026-10-26 (pedido del usuario: era difícil
	de navegar). A la izquierda las secciones agrupadas por a quién afectan:
		JUGADOR         Jugador, Compras, Moverse, Moderación (al elegido arriba)
		ESTE SERVIDOR   Mundo, Monstruos, Diversión
		TODOS           Global: anuncio, eventos, monstruo, diversión... en todos
		                los servidores a la vez (Admin/AdminGlobal)
		INFO            Servidores del juego y el registro de esta sesión
	Arriba de cada página, una franja del color del alcance dice a quién se
	aplica; el buscador de jugadores solo aparece en las de JUGADOR. Abajo,
	la última respuesta del servidor. Cada botón manda AdminCommand(nombre,
	valor, UserId del elegido); las de todos los servidores van con "g:".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Style = require(script.Parent.Parent.Interface.Style)
local AdminLog = require(script.Parent.AdminLog)
local AdminMoves = require(script.Parent.AdminMoves)
local AdminRows = require(script.Parent.AdminRows)
local AdminSections = require(script.Parent.AdminSections)
local AdminTarget = require(script.Parent.AdminTarget)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local CARDS = Style.PALETTE.Cards
local SIDE_WIDTH = 190
local ITEM_HEIGHT = 40
local BANNER_HEIGHT = 34
local STATUS_HEIGHT = 28
local GAP = 10

local SCOPES = AdminSections.SCOPES

local AdminPanel = {}

function AdminPanel.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	while player:GetAttribute(Protocol.PlayerAttributes.IsAdmin) ~= true do
		player:GetAttributeChangedSignal(Protocol.PlayerAttributes.IsAdmin):Wait()
	end
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local command = remotes:WaitForChild(Protocol.Remotes.AdminCommand) :: RemoteEvent
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	local window = Window.create(screen, "Admin", "Panel admin", Vector2.new(1040, 700))
	HudButtons.top("Admin", "crown", window.toggle)
	AdminMoves.start()

	local side = AdminSections.sidebar(window.content, SIDE_WIDTH)
	local main = Instance.new("Frame")
	main.Name = "Principal"
	main.BackgroundTransparency = 1
	main.Position = UDim2.fromOffset(SIDE_WIDTH + GAP, 0)
	main.Size = UDim2.new(1, -(SIDE_WIDTH + GAP), 1, 0)
	main.Parent = window.content

	local banner = Instance.new("Frame")
	banner.Name = "Alcance"
	banner.Size = UDim2.new(1, 0, 0, BANNER_HEIGHT)
	banner.Parent = main
	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 10)
	bannerCorner.Parent = banner
	local bannerText = Style.text(banner, "Texto", 22, nil, 2)
	bannerText.Position = UDim2.fromOffset(12, 0)
	bannerText.Size = UDim2.new(1, -24, 1, 0)
	bannerText.TextXAlignment = Enum.TextXAlignment.Left

	local targetZone = Instance.new("Frame")
	targetZone.Name = "ZonaObjetivo"
	targetZone.BackgroundTransparency = 1
	targetZone.Position = UDim2.fromOffset(0, BANNER_HEIGHT + GAP)
	targetZone.Parent = main
	local target = AdminTarget.mount(targetZone)
	targetZone.Size = UDim2.new(1, 0, 0, target.height)

	local area = Instance.new("Frame")
	area.Name = "Paginas"
	area.BackgroundTransparency = 1
	area.Parent = main

	local status = Style.text(main, "Respuesta", 20, UIConfig.Colors.TextMuted, 1.5)
	status.AnchorPoint = Vector2.new(0, 1)
	status.Position = UDim2.fromScale(0, 1)
	status.Size = UDim2.new(1, 0, 0, STATUS_HEIGHT)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = "Aquí sale la respuesta del servidor"

	local log = AdminLog.log(area)
	local function send(name: string, value: any)
		command:FireServer(name, value, target.get().UserId)
		local who = if string.sub(name, 1, 2) == "g:" then "todos" else target.get().DisplayName
		log.add(
			`→ {name} {if value ~= nil then tostring(value) else ""} ({who})`,
			UIConfig.Colors.TextMuted
		)
	end
	local function sendGlobal(name: string, value: any)
		send(`g:{name}`, value)
	end
	notice.OnClientEvent:Connect(function(kind: unknown, text: unknown)
		if kind == "admin" and type(text) == "string" then
			status.Text = text
			status.TextColor3 = if string.sub(text, 1, 6) == "Error:"
				then UIConfig.Colors.Bite
				else UIConfig.Colors.Success
			log.add(text, status.TextColor3)
		end
	end)

	local entries: { { button: TextButton, frame: GuiObject, section: AdminSections.Section } } = {}
	local function show(index: number)
		local section = entries[index].section
		local scope = SCOPES[section.scope]
		local personal = section.scope == "player"
		targetZone.Visible = personal
		local top = BANNER_HEIGHT + GAP + (if personal then target.height else 0)
		area.Position = UDim2.fromOffset(0, top)
		area.Size = UDim2.new(1, 0, 1, -(top + STATUS_HEIGHT + 4))
		banner.BackgroundColor3 = scope.color
		bannerText.Text = if personal
			then `{section.title}  ·  se aplica al jugador elegido abajo`
			elseif section.scope == "server" then `{section.title}  ·  solo en ESTE servidor`
			elseif section.scope == "global" then "⚠ TODOS LOS SERVIDORES DEL JUEGO A LA VEZ"
			else section.title
		for other, entry in entries do
			local on = other == index
			entry.frame.Visible = on
			entry.button.BackgroundColor3 = if on
				then CARDS.Yellow
				else SCOPES[entry.section.scope].color
		end
	end

	local order = 0
	for _, scope in AdminSections.SCOPE_ORDER do
		order += 1
		local header = Style.text(side, "Grupo", 18, UIConfig.Colors.Coins, 1.5)
		header.LayoutOrder = order
		header.Size = UDim2.new(1, -8, 0, 22)
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Text = SCOPES[scope].group
		for _, section in AdminSections.SECTIONS do
			if section.scope ~= scope then
				continue
			end
			order += 1
			local button = Style.button(side, section.title, SCOPES[scope].color, section.title)
			button.LayoutOrder = order
			button.Size = UDim2.new(1, -8, 0, ITEM_HEIGHT)
			local frame: GuiObject
			if section.fill then
				local page = AdminRows.page(
					area,
					if scope == "global" then sendGlobal else send,
					SCOPES[scope].color
				)
				section.fill(page)
				frame = page.frame
			elseif section.title == "Servidores" then
				frame = AdminLog.servers(area, send)
			else
				frame = log.frame
			end
			table.insert(entries, { button = button, frame = frame, section = section })
			local index = #entries
			button.Activated:Connect(function()
				show(index)
			end)
		end
	end
	show(1)
end

return AdminPanel
