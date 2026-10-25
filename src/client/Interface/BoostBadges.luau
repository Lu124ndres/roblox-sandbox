--!strict
--[[
	BoostBadges

	Los potenciadores del jugador, cada uno con su ícono y el porcentaje
	debajo, sin placa (pedido del usuario el 2026-10-21). Siempre se ven, en
	+0% si no aplican:
		Premium  el ícono de Roblox Premium; tocarlo ofrece Premium si no lo tiene
		Evento   el ícono del evento activo y cuánto da (un rayo en +0% si no hay)
		Amigos   +10 % por amigo de Roblox en el servidor (hasta 5); tocarlo abre
		         la invitación de Roblox (SocialService), y si un amigo nuevo
		         entra por ella los dos ganan premio (server/Social/Referrals)
		Grupo    +10 % si ya reclamó el regalo del letrero de la plaza
		         (Menus/GroupSign); con el mouse encima dice que es +10 % de
		         suerte y +10 % de poder (BadgeHint)
	Después, mientras duran, los x2 personales de poder y monedas con su
	tiempo (Interface/TimedBadges).
	Siempre abajo a la izquierda. En táctil quedan detrás del joystick y son
	solo para ver: no reciben toques, así no le quitan ninguno al joystick.
	Los números los calcula el servidor (atributo AmigosEnServidor, carpeta de
	impulsos); aquí se muestran.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local Events = require(ReplicatedStorage.Shared.Config.Events)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local ServerEvents = require(ReplicatedStorage.Shared.ServerEvents)
local BadgeHint = require(script.Parent.BadgeHint)
local Device = require(script.Parent.Device)
local Icons = require(script.Parent.Icons)
local Layout = require(script.Parent.Layout)
local Style = require(script.Parent.Style)
local TimedBadges = require(script.Parent.TimedBadges)

local GROUP = Config.Social.group
local SIZE = 56 -- ancho y alto de cada insignia (el ícono; el número va encima de su borde de abajo)
local GAP = 6
local MARGIN = 12
local IDLE_EVENT_ICON = "bolt"
local REFRESH_SECONDS = 0.5 -- el evento empieza y vence por la hora
local ON_COLOR = Color3.fromRGB(140, 255, 120)
local OFF_COLOR = Color3.new(1, 1, 1)

type Badge = { button: TextButton, icon: GuiObject, value: TextLabel }

local BoostBadges = {}

local function percent(multiplier: number): number
	return math.round((multiplier - 1) * 100)
end

-- Cuánto da el evento, en %: cada evento mejora una sola cosa (Config/Events).
local function eventPercent(kind: Events.EventDef?): number
	if not kind then
		return 0
	elseif kind.luck then
		return math.round(kind.luck * 100)
	elseif kind.biteDelay then
		return percent(1 / kind.biteDelay)
	end
	return percent(kind.coins or kind.power or 1)
end

local function badge(row: Frame, name: string, order: number, icon: GuiObject?): Badge
	local button = Instance.new("TextButton")
	button.Name = name
	button.LayoutOrder = order
	button.Text = ""
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromOffset(SIZE, SIZE)
	button.Interactable = not Device.touch()
	button.Parent = row
	local image = icon or Icons.view(button, IDLE_EVENT_ICON)
	image.Parent = button
	image.AnchorPoint = Vector2.new(0.5, 0)
	image.Position = UDim2.fromScale(0.5, 0)
	image.Size = UDim2.fromScale(0.8, 0.8)
	local value = Style.text(button, "Porcentaje", 20, OFF_COLOR, 2.5)
	value.AnchorPoint = Vector2.new(0.5, 1)
	value.Position = UDim2.fromScale(0.5, 1)
	value.Size = UDim2.new(1, 8, 0, 22)
	value.ZIndex = 2
	return { button = button, icon = image, value = value }
end

local function show(entry: Badge, amount: number)
	entry.value.Text = `+{amount}%`
	entry.value.TextColor3 = if amount > 0 then ON_COLOR else OFF_COLOR
end

function BoostBadges.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local row = Instance.new("Frame")
	row.Name = "Impulsos"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(SIZE * 4 + GAP * 3, SIZE)
	row.AutomaticSize = Enum.AutomaticSize.X -- crece con los impulsos con tiempo
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, GAP)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	Layout.scaleWith(row)

	local glyph = Instance.new("ImageLabel")
	glyph.BackgroundTransparency = 1
	glyph.Image = Assets.UI.PremiumIcon -- el ícono de Premium que trae Roblox
	glyph.ScaleType = Enum.ScaleType.Fit
	local premium = badge(row, "Premium", 1, glyph)
	local event = badge(row, "Evento", 2, nil)
	local friends = badge(row, "Amigos", 3, Icons.view(row, "friends"))
	local group = badge(row, "Grupo", 4, Icons.view(row, "group"))
	TimedBadges.mount(row, 5, function(name: string, order: number, icon: GuiObject): Badge
		return badge(row, name, order, icon)
	end)

	row.AnchorPoint = Vector2.new(0, 1)
	row.Position = UDim2.new(0, MARGIN, 1, -MARGIN)
	row.Parent = screen
	Layout.avoid(row) -- las columnas no se le meten encima ni debajo

	show(premium, percent(Perks.premiumMultiplier(player)))
	premium.button.Activated:Connect(function()
		if player.MembershipType ~= Enum.MembershipType.Premium then
			pcall(MarketplaceService.PromptPremiumPurchase, MarketplaceService, player)
		end
	end)

	local function refreshFriends()
		show(friends, percent(Perks.friendMultiplier(player)))
	end
	friends.button.Activated:Connect(function()
		local ok, allowed = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if ok and allowed then
			pcall(SocialService.PromptGameInvite, SocialService, player)
		end
	end)
	player
		:GetAttributeChangedSignal(Protocol.PlayerAttributes.FriendsInServer)
		:Connect(refreshFriends)
	refreshFriends()

	-- La suerte y el poder del grupo valen lo mismo (+10 %): el número es uno, el texto dice los dos.
	local function refreshGroup()
		show(group, math.round(Perks.groupLuck(player) * 100))
	end
	BadgeHint.attach(group.button, function(): string
		local luck, power = math.round(GROUP.luck * 100), math.round(GROUP.power * 100)
		local gift = `+{luck}% suerte y +{power}% poder`
		return if Perks.groupLuck(player) > 0 then gift else `Letrero de la plaza: {gift}`
	end)
	player:GetAttributeChangedSignal(Protocol.PlayerAttributes.GroupClaimed):Connect(refreshGroup)
	refreshGroup()

	local eventIcon = IDLE_EVENT_ICON
	task.spawn(function()
		while true do
			local kind = ServerEvents.active()
			local wanted = if kind then kind.icon else IDLE_EVENT_ICON
			if
				wanted ~= eventIcon
				and event.icon:IsA("ImageLabel")
				and Icons.paint(event.icon, wanted)
			then
				eventIcon = wanted
			end
			show(event, eventPercent(kind))
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return BoostBadges
