--!strict
--[[
	DailyWindow

	Recompensa diaria como la de los simuladores: un regalo grande asoma sobre
	el título, los días 1 a 6 en tarjetas de piedra volcánica (Menus/DailyCard)
	en una grilla de 3 x 2 y el día 7, el gran premio, alto a la derecha. Las
	cobradas dicen ¡RECLAMADO!, la de hoy tiene marco de lava y el botón
	¡RECLAMAR!, las que faltan su día. Debajo, la racha (+10% de monedas y poder
	por día, shared/RetentionBonus) y lo que trae el próximo cobro. Se
	abre sola al entrar si hoy todavía no se cobró, y el botón Premio del
	HUD lleva un punto rojo mientras tanto. El servidor decide (ClaimDaily).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RetentionBonus = require(ReplicatedStorage.Shared.RetentionBonus)
local RewardScale = require(ReplicatedStorage.Shared.RewardScale)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local DailyCard = require(script.Parent.DailyCard)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local DAILY = Config.Retention.daily
local STREAK = Config.Retention.streakBonus
local BADGE_SIZE = 112 -- el regalo que asoma sobre la esquina del título
local BADGE_ROOM = 76 -- cuánto se corre el título para dejarle lugar

local DailyWindow = {}

local function number(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

-- Día UTC del servidor (mismo cálculo que DailyReward).
local function today(): number
	return math.floor(Workspace:GetServerTimeNow() / 86400)
end

local function dayCoins(player: Player, day: number): number
	return RewardScale.share(player, DAILY[day], Config.Retention.dailyShare[day])
		* Perks.dailyMultiplier(player)
end

-- "1.2K monedas y +1 giro" del día `day` de la racha (después del 7, el 7).
local function dayReward(player: Player, day: number): string
	local index = math.clamp(day, 1, #DAILY)
	local spins = Config.Retention.dailySpins[index] or 0
	local coins = `{NumberFormat.short(dayCoins(player, index))} monedas`
	return if spins > 0 then `{coins} y +{spins} giro{if spins == 1 then "" else "s"}` else coins
end

-- Ícono grande de regalo que asoma sobre la esquina del título (el título se corre a la
-- derecha para dejarle lugar), como el calendario de los simuladores.
local function titleBadge(frame: Frame)
	local heading = frame:FindFirstChild("Encabezado")
	if heading and heading:IsA("GuiObject") then
		heading.Position += UDim2.fromOffset(BADGE_ROOM, 0)
	end
	local badge = Icons.view(frame, "gift")
	badge.Name = "IconoTitulo"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromOffset(34, 30)
	badge.Size = UDim2.fromOffset(BADGE_SIZE, BADGE_SIZE)
	badge.Rotation = -10
	badge.ZIndex = 5
end

local function area(parent: Instance, name: string, position: UDim2, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Position = position
	frame.Size = size
	frame.Parent = parent
	return frame
end

function DailyWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimDaily) :: RemoteEvent
	local window = Window.create(screen, "Diario", "Premio diario", Vector2.new(880, 520))
	local hud = HudButtons.top("Premio", "gift", window.toggle)
	titleBadge(window.frame)

	-- Días 1 a 6 en una grilla de 3 x 2; el último, alto a la derecha.
	local grid = area(window.content, "Dias", UDim2.new(), UDim2.fromScale(0.74, 0.84))
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(1 / 3, -8, 0.5, -6)
	layout.CellPadding = UDim2.fromOffset(12, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	local side =
		area(window.content, "GranPremio", UDim2.new(0.74, 12, 0, 0), UDim2.new(0.26, -12, 0.84, 0))

	-- Franja de abajo en un hueco de piedra: la racha y lo que trae el próximo cobro.
	local info = area(window.content, "Racha", UDim2.fromScale(0, 0.865), UDim2.fromScale(1, 0.135))
	Kit.skin(info, "hondo")
	local streakLine = Style.text(info, "Racha", 24, nil, 2.5)
	Kit.gold(streakLine)
	streakLine.Position = UDim2.new(0, 14, 0.08, 0)
	streakLine.Size = UDim2.new(1, -28, 0.44, 0)
	local tomorrowLine = Style.text(info, "Manana", 20, nil, 2.5)
	tomorrowLine.Position = UDim2.new(0, 14, 0.52, 0)
	tomorrowLine.Size = UDim2.new(1, -28, 0.4, 0)

	local function available(): boolean
		return player:GetAttribute(ATTR.DataLoaded) == true
			and number(player, ATTR.DailyDay) ~= today()
	end

	local function claim()
		if available() then
			claimRemote:FireServer()
		end
	end

	local function render()
		for _, holder in { grid, side } do
			for _, child in holder:GetChildren() do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
		end
		local ready = available()
		local streak = number(player, ATTR.DailyStreak)
		local continues = number(player, ATTR.DailyDay) >= today() - 1
		local done = if ready then (if continues then streak else 0) else streak
		-- Hoy toca el día done + 1 (después del 7, el 7); si ya se cobró, ese es el de mañana.
		local following = math.min(done + 1, #DAILY)
		for day = 1, #DAILY do
			local state: DailyCard.State = if ready and day == following
				then "today"
				elseif day <= math.min(done, #DAILY) then "claimed"
				elseif day == following then "next"
				else "future"
			DailyCard.build(if day == #DAILY then side else grid, {
				day = day,
				coins = NumberFormat.short(dayCoins(player, day)),
				spins = Config.Retention.dailySpins[day] or 0,
				state = state,
				big = day == #DAILY,
				onClaim = claim,
			})
		end
		local days = RetentionBonus.streakDays(player)
		local percent = math.round(RetentionBonus.streakBonus(days) * 100)
		streakLine.Text =
			`Racha: {days} día{if days == 1 then "" else "s"} · +{percent}% monedas y poder`
		local more = if days >= STREAK.maxDays
			then " (racha al máximo: ¡no la cortes!)"
			else ` y +{math.round(STREAK.perDay * 100)}% más`
		local label = if ready then "Hoy" else "Mañana" -- el próximo cobro es el día days + 1
		tomorrowLine.Text = `{label}: {dayReward(player, days + 1)}{more}`
		hud.setAlert(ready)
	end

	window.onOpen(render)
	for _, attribute in { ATTR.DailyDay, ATTR.DailyStreak, ATTR.DataLoaded } do
		player:GetAttributeChangedSignal(attribute):Connect(render)
	end
	render()

	-- Al entrar, si hoy toca, se abre sola (cuando ya cargaron los datos).
	task.spawn(function()
		while player:GetAttribute(ATTR.DataLoaded) ~= true do
			player:GetAttributeChangedSignal(ATTR.DataLoaded):Wait()
		end
		task.wait(3)
		if available() then
			window.open()
		end
	end)
end

return DailyWindow
