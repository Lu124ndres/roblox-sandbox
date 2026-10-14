--!strict
--[[
	RigParts

	Piezas de la pesca de un jugador que FishingVisuals crea y destruye: el
	corcho con su sedal, el "!" sobre la cabeza y el pez que salta. Separado
	para que FishingVisuals quede como la máquina de estados y nada más.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ArmPose = require(script.Parent.ArmPose)
local Bobber = require(script.Parent.Bobber)
local CatchShow = require(script.Parent.CatchShow)
local Rod = require(script.Parent.Rod)

local ATTR = Protocol.PlayerAttributes

export type Rig = {
	pose: ArmPose.ArmPose?,
	rod: Rod.Rod?,
	bobber: Bobber.Bobber?,
	line: Beam?,
	alert: BillboardGui?,
	follow: RBXScriptConnection?, -- mueve la caña con el brazo cada cuadro
	generation: number, -- invalida tareas diferidas de un estado anterior
}

local RigParts = {}

-- Guarda la caña y suelta el brazo.
function RigParts.dropRod(rig: Rig)
	if rig.follow then
		rig.follow:Disconnect()
		rig.follow = nil
	end
	if rig.rod then
		rig.rod.model:Destroy()
		rig.rod = nil
	end
	if rig.pose then
		rig.pose.destroy()
		rig.pose = nil
	end
end

function RigParts.headPosition(character: Model): Vector3
	local head = character:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head.Position else character:GetPivot().Position
end

function RigParts.clearBobber(rig: Rig)
	if rig.line then
		rig.line:Destroy()
		rig.line = nil
	end
	if rig.bobber then
		rig.bobber.destroy()
		rig.bobber = nil
	end
end

function RigParts.clearAlert(rig: Rig)
	if rig.alert then
		rig.alert:Destroy()
		rig.alert = nil
	end
end

function RigParts.attachLine(rig: Rig)
	if not rig.rod or not rig.bobber then
		return
	end
	local line = Instance.new("Beam")
	line.Attachment0 = rig.rod.tip
	line.Attachment1 = rig.bobber.attachment
	line.Color = ColorSequence.new(UIConfig.Colors.Line)
	line.Width0 = 0.05
	line.Width1 = 0.05
	line.FaceCamera = true
	line.Segments = 10
	line.Parent = rig.rod.model
	rig.line = line
end

function RigParts.launch(rig: Rig, target: Vector3, floating: boolean)
	RigParts.clearBobber(rig)
	local from = if rig.rod then rig.rod.tip.WorldPosition else target
	rig.bobber = Bobber.cast(from, target, floating)
	RigParts.attachLine(rig)
end

function RigParts.showAlert(rig: Rig, character: Model)
	RigParts.clearAlert(rig)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "!"
	label.TextScaled = true
	label.FontFace = UIConfig.Fonts.Title
	label.TextColor3 = UIConfig.Colors.Coins
	label.TextStrokeTransparency = 0
	label.Parent = billboard
	billboard.Parent = head
	rig.alert = billboard
end

function RigParts.catchFish(rig: Rig, player: Player, character: Model, target: Vector3)
	local fishId = player:GetAttribute(ATTR.FishingCatch)
	local count = player:GetAttribute(ATTR.FishingCatchCount)
	RigParts.clearBobber(rig)
	CatchShow.play(
		player,
		character,
		target,
		if type(fishId) == "string" then fishId else "Sardina",
		if type(count) == "number" then count else 1
	)
end

return RigParts
