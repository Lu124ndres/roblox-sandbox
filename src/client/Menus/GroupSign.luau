--!strict
--[[
	GroupSign

	Letrero del regalo del grupo en la plaza (Menus/PlazaSign), junto al Estanque de Jade y de cara
	al spawn (pedido del usuario el 2026-10-21; reemplaza el escudo de la barra
	de arriba):
		1. Dale me gusta     (solo texto: Roblox no deja saber quién dio me gusta)
		2. Únete al grupo
		3. +10% de suerte y +10% de poder para siempre
	y un botón RECLAMAR: si no está en el grupo abre la invitación de Roblox; si
	ya está y jugó Config.Social.group.minutes, pide el premio (remote
	ClaimGroup; el servidor lo revisa todo, server/Social/GroupReward).
	Las piezas son primitivas locales de cada cliente (como los carteles de los
	estanques): no hay que guardarlas en la isla. La SurfaceGui va en PlayerGui
	para que el botón reciba clics.
]]

local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local PlazaSign = require(script.Parent.PlazaSign)

local GROUP = Config.Social.group
local ATTR = Protocol.PlayerAttributes
local PALETTE = Style.PALETTE
-- { x, z } entre el Estanque de Jade y el camino del anillo, cerca de la fogata (pedido del
-- usuario el 2026-10-21, con una foto); mira hacia el spawn, de donde llegan los jugadores.
local SPOT = Vector2.new(-26, 102)
local BOARD = Vector3.new(20, 11, 0.8) -- ancho, alto y grosor del tablero (studs)
local LIFT = 3 -- el tablero empieza a esta altura sobre el suelo
local PIXELS_PER_STUD = 50
local CHECK_MEMBER_SECONDS = 10

local GroupSign = {}

-- Tablero y postes, de cara al spawn. Devuelve el tablero.
local function build(): Part
	return PlazaSign.build("LetreroGrupo", SPOT, BOARD, LIFT)
end

local function line(parent: Instance, name: string, text: string, color: Color3, y: number)
	local label = Style.text(parent, name, 90, color, 6)
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromScale(0.06, y)
	label.Size = UDim2.fromScale(0.6, 0.17)
	return label
end

function GroupSign.start()
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local claimRemote = remotes:WaitForChild(Protocol.Remotes.ClaimGroup) :: RemoteEvent
	local board = build()

	local gui = Instance.new("SurfaceGui")
	gui.Name = "LetreroGrupo"
	gui.Adornee = board
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundTransparency = 1
	panel.Size = UDim2.fromScale(1, 1)
	panel.Parent = gui
	Kit.skin(panel, "panel")

	local luck, power = math.round(GROUP.luck * 100), math.round(GROUP.power * 100)
	local gift = `+{luck}% suerte y +{power}% poder`
	line(panel, "Paso1", "1. Dale me gusta", Color3.fromRGB(110, 235, 90), 0.08)
	line(panel, "Paso2", "2. Únete al grupo", Color3.fromRGB(110, 200, 255), 0.27)
	line(panel, "Paso3", `3. ¡{gift}!`, Color3.fromRGB(255, 220, 90), 0.46)
	local icon = Icons.view(panel, "group")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.82, 0.34)
	icon.Size = UDim2.fromScale(0.3, 0.52)
	local prize = Style.text(panel, "Premio", 110, Color3.fromRGB(140, 255, 120), 7)
	prize.Text = if luck == power then `+{luck}%` else `+{luck}/{power}%`
	prize.AnchorPoint = Vector2.new(0.5, 0.5)
	prize.Position = UDim2.fromScale(0.82, 0.6)
	prize.Size = UDim2.fromScale(0.32, 0.2)
	prize.ZIndex = 3
	local prizeDetail = Style.text(panel, "PremioDetalle", 60, Color3.fromRGB(140, 255, 120), 4)
	prizeDetail.Text = "suerte y poder"
	prizeDetail.AnchorPoint = Vector2.new(0.5, 0)
	prizeDetail.Position = UDim2.fromScale(0.82, 0.71)
	prizeDetail.Size = UDim2.fromScale(0.32, 0.1)
	prizeDetail.ZIndex = 3
	local status = Style.text(panel, "Estado", 50, nil, 4)
	status.Position = UDim2.fromScale(0.06, 0.64)
	status.Size = UDim2.fromScale(0.6, 0.1)
	local claim = Style.button(panel, "Reclamar", PALETTE.Buy, "RECLAMAR")
	claim.AnchorPoint = Vector2.new(0.5, 1)
	claim.Position = UDim2.fromScale(0.36, 0.94)
	claim.Size = UDim2.fromScale(0.46, 0.18)
	local claimText = claim:FindFirstChild("Texto") :: TextLabel
	-- El botón trae el tamaño de letra de la pantalla; en el letrero hay muchos más píxeles.
	local claimLimit = claimText:FindFirstChildOfClass("UITextSizeConstraint")
	if claimLimit then
		claimLimit.MaxTextSize = 80
	end

	local member = false
	local function secondsLeft(): number
		local joined = player:GetAttribute(ATTR.JoinedAt)
		local start = if type(joined) == "number" then joined else Workspace:GetServerTimeNow()
		return math.max(0, GROUP.minutes * 60 - (Workspace:GetServerTimeNow() - start))
	end
	local function refresh()
		local claimed = player:GetAttribute(ATTR.GroupClaimed) == true
		local left = math.ceil(secondsLeft())
		status.Text = if claimed
			then `¡Ya tienes {gift}!`
			elseif GROUP.groupId == 0 then "Muy pronto"
			elseif not member then `Únete y juega {GROUP.minutes} minutos`
			elseif left > 0 then string.format(
				"Juega un poco más: %d:%02d",
				left // 60,
				left % 60
			)
			else "¡Listo para reclamar!"
		claimText.Text = if claimed then "¡RECLAMADO!" else "RECLAMAR"
		local usable = GROUP.groupId ~= 0 and not claimed and (not member or left <= 0)
		local tint = if usable then PALETTE.Buy else PALETTE.Disabled
		if claim.BackgroundColor3 ~= tint then
			claim.BackgroundColor3 = tint -- la piedra del botón se tiñe sola
		end
	end
	local function checkMember()
		if GROUP.groupId == 0 then
			return
		end
		local ok, result = pcall(function()
			return player:IsInGroupAsync(GROUP.groupId)
		end)
		member = ok and result == true
	end

	claim.Activated:Connect(function()
		if GROUP.groupId == 0 or player:GetAttribute(ATTR.GroupClaimed) == true then
			return
		elseif not member then
			pcall(function()
				GroupService:PromptJoinAsync(GROUP.groupId)
			end)
			checkMember()
			refresh()
		else
			claimRemote:FireServer() -- si faltan minutos, el servidor lo avisa (Notices)
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

return GroupSign
