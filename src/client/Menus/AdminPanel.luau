--!strict
--[[
	AdminPanel

	Panel de pruebas para los administradores (atributo EsAdmin, lo pone el
	servidor; nadie más ve el botón). Arriba se elige a qué jugador se le
	aplican las órdenes (AdminTarget: tú u otro del servidor) y debajo hay
	cinco pestañas (reordenadas el 2026-10-21, pedido del usuario):
		Jugador    números, canasta, mejoras, regalos y reiniciar (AdminPages)
		Compras    todo lo que se compra con Robux, de una vez o por partes
		Moverse    volar y sin colisión (solo tú), velocidad, llevar, ir y traer
		Mundo      la hora del cielo, eventos y entrenamiento del servidor
		Monstruos  cada monstruo por etapa, la barra y el descanso
	Cada botón manda AdminCommand(nombre, valor, UserId del elegido); el
	servidor vuelve a comprobar que seas admin y responde con un aviso.
	Las órdenes están en server/Admin; volar y sin colisión, en AdminMoves.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Style = require(script.Parent.Parent.Interface.Style)
local AdminMoves = require(script.Parent.AdminMoves)
local AdminPages = require(script.Parent.AdminPages)
local AdminPagesWorld = require(script.Parent.AdminPagesWorld)
local AdminRows = require(script.Parent.AdminRows)
local AdminTarget = require(script.Parent.AdminTarget)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local CARDS = Style.PALETTE.Cards
local TAB_HEIGHT = 40
local TAB_WIDTH = 150

type Tab = { title: string, fill: (page: AdminRows.Page) -> () }
local TABS: { Tab } = {
	{ title = "Jugador", fill = AdminPages.player },
	{ title = "Compras", fill = AdminPages.shop },
	{ title = "Moverse", fill = AdminPagesWorld.moves },
	{ title = "Mundo", fill = AdminPagesWorld.world },
	{ title = "Monstruos", fill = AdminPagesWorld.giants },
}

local AdminPanel = {}

function AdminPanel.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	while player:GetAttribute(Protocol.PlayerAttributes.IsAdmin) ~= true do
		player:GetAttributeChangedSignal(Protocol.PlayerAttributes.IsAdmin):Wait()
	end
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local command = remotes:WaitForChild(Protocol.Remotes.AdminCommand) :: RemoteEvent
	local window = Window.create(screen, "Admin", "Panel admin", Vector2.new(900, 640))
	HudButtons.top("Admin", "crown", window.toggle)
	AdminMoves.start()

	local target = AdminTarget.mount(window.content)
	local function send(name: string, value: any)
		command:FireServer(name, value, target.get().UserId)
	end

	local tabs = Instance.new("Frame")
	tabs.Name = "Pestanas"
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromOffset(0, target.height)
	tabs.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
	tabs.Parent = window.content
	local flow = Instance.new("UIListLayout")
	flow.FillDirection = Enum.FillDirection.Horizontal
	flow.Padding = UDim.new(0, 10)
	flow.SortOrder = Enum.SortOrder.LayoutOrder
	flow.Parent = tabs

	local area = Instance.new("Frame")
	area.Name = "Paginas"
	area.BackgroundTransparency = 1
	area.Position = UDim2.fromOffset(0, target.height + TAB_HEIGHT + 12)
	area.Size = UDim2.new(1, 0, 1, -(target.height + TAB_HEIGHT + 12))
	area.Parent = window.content

	local entries: { { button: TextButton, page: AdminRows.Page } } = {}
	local function show(index: number)
		for other, entry in entries do
			local on = other == index
			entry.page.frame.Visible = on
			entry.button.BackgroundColor3 = if on then CARDS.Yellow else Style.PALETTE.Disabled
			local gradient = entry.button:FindFirstChildOfClass("UIGradient")
			if gradient then
				gradient.Enabled = on
			end
		end
	end
	for index, tab in TABS do
		local button = Style.button(tabs, tab.title, CARDS.Yellow, tab.title)
		button.LayoutOrder = index
		button.Size = UDim2.fromOffset(TAB_WIDTH, TAB_HEIGHT)
		local page = AdminRows.page(area, send)
		tab.fill(page)
		table.insert(entries, { button = button, page = page })
		button.Activated:Connect(function()
			show(index)
		end)
	end
	show(1)
end

return AdminPanel
