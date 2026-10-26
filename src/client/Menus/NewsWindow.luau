--!strict
--[[
	NewsWindow

	Ventana NOVEDADES: lo que trae la última actualización (Config/Updates) en
	tarjetas con ícono, o la próxima como adelanto con su cuenta regresiva.
	Se abre sola una vez por actualización, cuando ya cargaron los datos y
	terminó el tutorial, y si el jugador no la vio (atributo NovedadVistaEn,
	lo anota el servidor con NewsSeen). Si la actualización sale mientras
	juega, se abre al quedar la pantalla libre. Tocar la cinta del contador
	(Interface/UpdateRibbon) también la abre.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local UpdateClock = require(ReplicatedStorage.Shared.UpdateClock)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local COLORS = UIConfig.Colors
local AUTO_OPEN_DELAY = 3 -- segundos después de estar listo (antes del premio diario)
local CHECK_SECONDS = 5 -- cada cuánto mira si salió una actualización mientras juega

local NewsWindow = {}

local function card(parent: Instance, item: UpdateClock.UpdateItem, order: number)
	local box = Instance.new("Frame")
	box.Name = `Novedad{order}`
	box.LayoutOrder = order
	box.BackgroundTransparency = 1
	box.Parent = parent
	Kit.skin(box, "hondo")
	local icon = Icons.view(box, item.icon)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	icon.Size = UDim2.fromScale(0.26, 0.7)
	icon.ZIndex = 2
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.Parent = icon
	local title = Style.text(box, "Titulo", 26)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromScale(0.3, 0.12)
	title.Size = UDim2.fromScale(0.66, 0.32)
	title.ZIndex = 2
	title.Text = item.title
	Kit.gold(title)
	local text = Style.text(box, "Texto", 18, COLORS.TextMuted, 1.5)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Position = UDim2.fromScale(0.3, 0.48)
	text.Size = UDim2.fromScale(0.66, 0.42)
	text.ZIndex = 2
	text.Text = item.text
end

-- La que se muestra: la última que salió o, si todavía no sale ninguna nueva, la próxima.
local function shown(): (UpdateClock.UpdateDef?, boolean)
	local upcoming = UpdateClock.upcoming()
	local fresh = UpdateClock.fresh()
	if fresh then
		return fresh, true
	elseif upcoming then
		return upcoming, false
	end
	return UpdateClock.current(), true
end

-- Devuelve la función que abre la ventana (para la cinta del contador).
function NewsWindow.start(screen: ScreenGui): () -> ()
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local seenRemote = remotes:WaitForChild(Protocol.Remotes.NewsSeen) :: RemoteEvent
	local window = Window.create(screen, "Novedades", "Novedades", Vector2.new(680, 470))

	local name = Style.text(window.content, "Actualizacion", 40)
	name.Size = UDim2.fromScale(1, 0.13)
	Kit.gold(name)
	local status = Instance.new("Frame")
	status.Name = "Estado"
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromScale(0, 0.13)
	status.Size = UDim2.fromScale(1, 0.08)
	status.Parent = window.content
	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statusLayout.Padding = UDim.new(0, 8)
	statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statusLayout.Parent = status
	-- Palabras y reloj aparte: AutoTranslate solo traduce las palabras.
	local words = Style.text(status, "Palabras", 24, COLORS.Success, 2)
	words.LayoutOrder = 1
	words.Size = UDim2.fromScale(0.45, 1)
	words.TextXAlignment = Enum.TextXAlignment.Right
	local clock = Style.text(status, "Reloj", 24, COLORS.Coins, 2)
	clock.LayoutOrder = 2
	clock.Size = UDim2.fromScale(0.45, 1)
	clock.TextXAlignment = Enum.TextXAlignment.Left

	local grid = Instance.new("Frame")
	grid.Name = "Tarjetas"
	grid.BackgroundTransparency = 1
	grid.Position = UDim2.fromScale(0, 0.24)
	grid.Size = UDim2.fromScale(1, 0.58)
	grid.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.5, -6, 0.5, -6)
	layout.CellPadding = UDim2.fromOffset(12, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local play = Style.button(window.content, "Jugar", Style.PALETTE.Buy, "¡A JUGAR!")
	play.AnchorPoint = Vector2.new(0.5, 1)
	play.Position = UDim2.fromScale(0.5, 1)
	play.Size = UDim2.fromScale(0.42, 0.14)
	play.Activated:Connect(window.close)

	local showing: string? = nil
	local released = true
	local function render()
		local update, out = shown()
		if not update then
			return
		end
		released = out
		if showing ~= update.id then
			showing = update.id
			name.Text = update.title
			for _, child in grid:GetChildren() do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			for index, item in update.items do
				card(grid, item, index)
			end
		end
		words.Text = if out then "¡YA ESTÁ AQUÍ!" else "LLEGA EN"
		words.Size = if out then UDim2.fromScale(1, 1) else UDim2.fromScale(0.45, 1)
		words.TextXAlignment = if out then Enum.TextXAlignment.Center else Enum.TextXAlignment.Right
		clock.Visible = not out
		if not out then
			clock.Text = UpdateClock.format(update.at - UpdateClock.now())
		end
	end
	window.onOpen(render)
	task.spawn(function()
		while true do
			if window.isOpen() and not released then
				render()
			end
			task.wait(1)
		end
	end)

	local function ready(): boolean
		local step = player:GetAttribute(ATTR.Tutorial)
		return player:GetAttribute(ATTR.DataLoaded) == true
			and (if type(step) == "number" then step else 0) >= #Config.Retention.tutorial
	end
	local function unseen(): UpdateClock.UpdateDef?
		local current = UpdateClock.current()
		local seen = player:GetAttribute(ATTR.NewsSeenAt)
		if current and current.at > (if type(seen) == "number" then seen else 0) then
			return current
		end
		return nil
	end
	-- Se abre sola: al entrar (antes del premio diario) o cuando sale mientras juega.
	task.spawn(function()
		while not ready() do
			task.wait(0.5)
		end
		task.wait(AUTO_OPEN_DELAY)
		while true do
			if unseen() then
				Window.waitClosed()
				if unseen() then
					window.open()
					seenRemote:FireServer()
					task.wait(2) -- el servidor anota y publica NovedadVistaEn
				end
			end
			task.wait(CHECK_SECONDS)
		end
	end)
	return window.open
end

return NewsWindow
