--!strict
--[[
	DailyWindow

	Recompensa diaria: 7 tarjetas de regalo (día 1 a 7) con rayos y sus
	monedas; las de la racha ya cobrada en verde con ✓, la de hoy dorada y
	el botón grande ¡RECLAMAR!. Debajo, la racha (+10% de monedas y poder
	por día, shared/RetentionBonus) y lo que trae volver mañana. Se
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
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local ShopParts = require(script.Parent.Parent.Interface.ShopParts)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local CARDS = Style.PALETTE.Cards
local ATTR = Protocol.PlayerAttributes
local DAILY = Config.Retention.daily
local STREAK = Config.Retention.streakBonus

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

function DailyWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimDaily) :: RemoteEvent
	local window = Window.create(screen, "Diario", "Premio diario", Vector2.new(720, 360))
	local hud = HudButtons.top("Premio", "gift", window.toggle)

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0.56, 0)
	row.Parent = window.content
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(1 / 7, -8, 1, 0)
	layout.CellPadding = UDim2.fromOffset(8, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local claim = Style.button(window.content, "Reclamar", Style.PALETTE.Buy, "")
	claim.AnchorPoint = Vector2.new(0.5, 1)
	claim.Position = UDim2.fromScale(0.5, 1)
	claim.Size = UDim2.new(0.46, 0, 0.26, 0)
	local claimText = claim:FindFirstChild("Texto") :: TextLabel
	local streakLine = Style.text(window.content, "Racha", 26, UIConfig.Colors.Coins, 2.5)
	streakLine.Position = UDim2.fromScale(0, 0.575)
	streakLine.Size = UDim2.fromScale(1, 0.08)
	local tomorrowLine = Style.text(window.content, "Manana", 22, nil, 2.5)
	tomorrowLine.Position = UDim2.fromScale(0, 0.655)
	tomorrowLine.Size = UDim2.fromScale(1, 0.07)

	local function available(): boolean
		return player:GetAttribute(ATTR.DataLoaded) == true
			and number(player, ATTR.DailyDay) ~= today()
	end

	local function render()
		for _, child in row:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local streak = number(player, ATTR.DailyStreak)
		local continues = number(player, ATTR.DailyDay) >= today() - 1
		local done = if available() then (if continues then streak else 0) else streak
		local nextDay = if available() then done + 1 else 0
		local highlight = math.min(nextDay, #DAILY)
		for day = 1, #DAILY do
			local claimed = day <= math.min(done, #DAILY)
			local box = Instance.new("Frame")
			box.LayoutOrder = day
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = box
			Style.border(box, if day == highlight then 5 else 3)
			ShopParts.sunburst(
				box,
				if claimed then CARDS.Green elseif day == highlight then CARDS.Yellow else CARDS.Blue
			)
			box.Parent = row
			if day == highlight then
				local stroke = box:FindFirstChildOfClass("UIStroke") :: UIStroke
				stroke.Color = Color3.new(1, 1, 1)
			end
			local label = Style.text(box, "Dia", 24, nil, 2.5)
			label.Text = `Día {day}`
			label.Position = UDim2.fromScale(0, 0.03)
			label.Size = UDim2.fromScale(1, 0.2)
			local gift = Icons.view(box, if day == #DAILY then "chest" else "gift")
			gift.AnchorPoint = Vector2.new(0.5, 0)
			gift.Position = UDim2.fromScale(0.5, 0.24)
			gift.Size = UDim2.fromScale(0.85, 0.45)
			local coins = Style.text(box, "Monedas", 24, UIConfig.Colors.Coins, 2.5)
			coins.Text = NumberFormat.short(dayCoins(player, day))
			coins.Position = UDim2.fromScale(0.04, 0.72)
			coins.Size = UDim2.fromScale(0.92, 0.22)
			if claimed then
				local check = Style.text(box, "Hecho", 60, Style.PALETTE.Buy, 4)
				check.Text = "✓"
				check.AnchorPoint = Vector2.new(0.5, 0.5)
				check.Position = UDim2.fromScale(0.5, 0.46)
				check.Size = UDim2.fromScale(0.8, 0.5)
				if gift:IsA("ImageLabel") then
					gift.ImageTransparency = 0.4
				end
			end
		end
		local ready = available()
		local days = RetentionBonus.streakDays(player)
		local percent = math.round(RetentionBonus.streakBonus(days) * 100)
		streakLine.Text =
			`Racha: {days} día{if days == 1 then "" else "s"} · +{percent}% monedas y poder`
		local more = if days >= STREAK.maxDays
			then " (racha al máximo: ¡no la cortes!)"
			else ` y +{math.round(STREAK.perDay * 100)}% más`
		local label = if ready then "Hoy" else "Mañana" -- el próximo cobro es el día days + 1
		tomorrowLine.Text = `{label}: {dayReward(player, days + 1)}{more}`
		claimText.Text = if ready then "¡RECLAMAR!" else "Vuelve mañana"
		local tint = if ready then Style.PALETTE.Buy else Style.PALETTE.Disabled
		claim.BackgroundColor3 = tint
		local gradient = claim:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient:Destroy()
		end
		Style.gradient(claim, tint)
		hud.setAlert(ready)
	end

	claim.Activated:Connect(function()
		if available() then
			claimRemote:FireServer()
		end
	end)
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
