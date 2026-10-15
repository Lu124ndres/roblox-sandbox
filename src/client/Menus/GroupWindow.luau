--!strict
--[[
	GroupWindow

	Regalo por unirse al grupo (botón con el escudo en la barra de Roblox),
	con el estilo de la TIENDA: tarjeta dorada con el premio y una tarjeta
	por paso (azul pendiente, verde cumplido):
		1. Únete al grupo (abre el aviso de Roblox para unirse)
		2. Juega 15 minutos (cuenta desde que entró a esta partida)
		3. Reclamar: monedas e impulso de poder, una sola vez
	El servidor revisa todo de nuevo (remote ClaimGroup, Notice "group").
	Un punto rojo avisa cuando ya se puede reclamar.
]]

local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CardParts = require(script.Parent.Parent.Interface.CardParts)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local GROUP = Config.Social.group
local ATTR = Protocol.PlayerAttributes
local COLORS = UIConfig.Colors
local CHECK_MEMBER_SECONDS = 10
local STEP_HEIGHT = 64
local PALETTE = Style.PALETTE
local CARDS = PALETTE.Cards

local GroupWindow = {}

type Step = { card: Frame, text: TextLabel, color: Color3? }

-- Tarjeta de un paso: ícono, texto y (si se pasa) un botón a la derecha.
local function step(parent: Instance, y: number, icon: string): Step
	local card = CardParts.card(parent, "Paso", CARDS.Blue, 12)
	card.Position = UDim2.fromOffset(0, y)
	card.Size = UDim2.new(1, 0, 0, STEP_HEIGHT)
	local view = Icons.view(card, icon)
	view.Position = UDim2.fromOffset(6, 4)
	view.Size = UDim2.fromOffset(STEP_HEIGHT - 8, STEP_HEIGHT - 8)
	local text = Style.text(card, "Texto", 24, nil, 2.5)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Position = UDim2.fromOffset(STEP_HEIGHT + 4, 0)
	text.Size = UDim2.new(0.66, -STEP_HEIGHT, 1, 0)
	return { card = card, text = text }
end

local function paintStep(item: Step, done: boolean)
	local color = if done then CARDS.Green else CARDS.Blue
	if item.color ~= color then
		item.color = color
		CardParts.paint(item.card, color)
	end
end

function GroupWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimGroup) :: RemoteEvent
	local window = Window.create(screen, "Grupo", "Regalo del grupo", Vector2.new(560, 430))
	local hud = HudButtons.top("Grupo", "group", window.toggle)
	local content = window.content

	-- Premio: monedas y minutos de x2 poder, en una tarjeta dorada.
	local prize = CardParts.card(content, "Premio", CARDS.Yellow, 14)
	prize.Size = UDim2.new(1, 0, 0, 92)
	local coins, coinText = CardParts.iconText(prize, "coin", 34, nil)
	coins.Position = UDim2.new(0.04, 0, 0, 10)
	coins.Size = UDim2.new(0.46, 0, 0, 72)
	coinText.Text = NumberFormat.big(GROUP.coins)
	local boost, boostText = CardParts.iconText(prize, "bolt", 26, nil)
	boost.Position = UDim2.new(0.52, 0, 0, 16)
	boost.Size = UDim2.new(0.46, 0, 0, 60)
	boostText.Text = `x{Config.Social.personalBoostMultiplier} poder {GROUP.boostMinutes} min`

	local step1 = step(content, 106, "group")
	local join = Style.button(step1.card, "Unirme", COLORS.Power, "Unirme")
	join.AnchorPoint = Vector2.new(1, 0.5)
	join.Position = UDim2.new(1, -10, 0.5, 0)
	join.Size = UDim2.new(0.28, 0, 0, STEP_HEIGHT - 18)
	local step2 = step(content, 106 + STEP_HEIGHT + 12, "gift")
	local claim = Style.button(content, "Reclamar", PALETTE.Buy, "¡Reclamar!")
	claim.AnchorPoint = Vector2.new(0.5, 1)
	claim.Position = UDim2.fromScale(0.5, 1)
	claim.Size = UDim2.new(0.55, 0, 0, 62)
	local claimText = claim:FindFirstChild("Texto") :: TextLabel

	local member = false
	local function minutesLeft(): number
		local joined = player:GetAttribute(ATTR.JoinedAt)
		local start = if type(joined) == "number" then joined else Workspace:GetServerTimeNow()
		return math.max(0, GROUP.minutes * 60 - (Workspace:GetServerTimeNow() - start))
	end
	local function refresh()
		local claimed = player:GetAttribute(ATTR.GroupClaimed) == true
		local left = minutesLeft()
		step1.text.Text = if member then "1. En el grupo ✓" else "1. Únete al grupo del juego"
		paintStep(step1, member)
		join.Visible = not member and GROUP.groupId ~= 0
		local total = math.ceil(left)
		step2.text.Text = if left <= 0
			then `2. Jugaste {GROUP.minutes} minutos ✓`
			else `2. Juega {GROUP.minutes} min: faltan {string.format(
				"%d:%02d",
				total // 60,
				total % 60
			)}`
		paintStep(step2, left <= 0)
		local ready = GROUP.groupId ~= 0 and member and left <= 0 and not claimed
		claimText.Text = if GROUP.groupId == 0
			then "Pronto"
			elseif claimed then "¡Ya lo reclamaste!"
			else "¡Reclamar!"
		claim.Active = ready
		claim.AutoButtonColor = ready
		local tint = if ready then PALETTE.Buy else PALETTE.Disabled
		if claim.BackgroundColor3 ~= tint then
			claim.BackgroundColor3 = tint
			local gradient = claim:FindFirstChildOfClass("UIGradient")
			if gradient then
				gradient:Destroy()
			end
			Style.gradient(claim, tint)
		end
		hud.setAlert(ready)
	end

	local function checkMember()
		if GROUP.groupId == 0 then
			member = false
			return
		end
		local ok, result = pcall(function()
			return player:IsInGroupAsync(GROUP.groupId)
		end)
		member = ok and result == true
	end
	join.Activated:Connect(function()
		pcall(function()
			GroupService:PromptJoinAsync(GROUP.groupId)
		end)
		checkMember()
		refresh()
	end)
	claim.Activated:Connect(function()
		if claim.Active then
			claimRemote:FireServer()
		end
	end)
	task.spawn(function()
		local sinceCheck = CHECK_MEMBER_SECONDS
		while true do
			if sinceCheck >= CHECK_MEMBER_SECONDS then
				sinceCheck = 0
				checkMember()
			end
			refresh()
			task.wait(1)
			sinceCheck += 1
		end
	end)
end

return GroupWindow
