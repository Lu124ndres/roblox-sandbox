--!strict
--[[
	GroupWindow

	Regalo por unirse al grupo (botón con el escudo en la barra de Roblox):
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
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local GROUP = Config.Social.group
local ATTR = Protocol.PlayerAttributes
local COLORS = UIConfig.Colors
local CHECK_MEMBER_SECONDS = 10

local GroupWindow = {}

local function line(parent: Instance, y: number, size: number): TextLabel
	local label = Style.text(parent, "Linea", size, nil, 2)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.new(0.66, 0, 0.18, 0)
	return label
end

function GroupWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimGroup) :: RemoteEvent
	local window = Window.create(screen, "Grupo", "Regalo del grupo", Vector2.new(520, 330))
	local hud = HudButtons.top("Grupo", "group", window.toggle)

	local reward = Style.text(window.content, "Premio", 24, COLORS.Coins, 2)
	reward.Size = UDim2.new(1, 0, 0.16, 0)
	reward.Text =
		`Premio: {NumberFormat.big(GROUP.coins)} monedas + {GROUP.boostMinutes} min de x{Config.Social.personalBoostMultiplier} poder`
	local step1 = line(window.content, 0.22, 24)
	local join = Style.button(window.content, "Unirme", COLORS.Power, "Unirme")
	join.AnchorPoint = Vector2.new(1, 0)
	join.Position = UDim2.fromScale(1, 0.2)
	join.Size = UDim2.new(0.3, 0, 0.2, 0)
	local step2 = line(window.content, 0.46, 24)
	local claim = Style.button(window.content, "Reclamar", COLORS.Robux, "¡Reclamar!")
	claim.AnchorPoint = Vector2.new(0.5, 1)
	claim.Position = UDim2.fromScale(0.5, 1)
	claim.Size = UDim2.new(0.55, 0, 0.24, 0)
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
		step1.Text = if member then "1. En el grupo ✓" else "1. Únete al grupo del juego"
		step1.TextColor3 = if member then COLORS.Success else COLORS.Text
		join.Visible = not member and GROUP.groupId ~= 0
		local total = math.ceil(left)
		step2.Text = if left <= 0
			then `2. Jugaste {GROUP.minutes} minutos ✓`
			else `2. Juega {GROUP.minutes} min: faltan {string.format(
				"%d:%02d",
				total // 60,
				total % 60
			)}`
		step2.TextColor3 = if left <= 0 then COLORS.Success else COLORS.Text
		local ready = GROUP.groupId ~= 0 and member and left <= 0 and not claimed
		claimText.Text = if GROUP.groupId == 0
			then "Pronto"
			elseif claimed then "¡Ya lo reclamaste!"
			else "¡Reclamar!"
		claim.Active = ready
		claim.AutoButtonColor = ready
		claim.BackgroundTransparency = if ready then 0 else 0.5
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
