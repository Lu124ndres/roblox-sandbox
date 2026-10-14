--!strict
--[[
	CatchShow

	El momento de sacar un pez, visto por todos los jugadores. Crece con la
	rareza (Config.Economy.rarities):
		- todos: chapuzón, el pez salta del agua hasta sobre la cabeza del
		  jugador, da unos coletazos y se mete en la canasta de la espalda;
		- poco común o mejor: cartel flotante con la rareza, el nombre y "xN";
		- raro o mejor: el pez gira en el aire y el jugador lo muestra en alto
		  (trofeo) dentro de un haz de luz del color de la rareza;
		- legendario o mítico: además onda dorada y la cámara tiembla un poco
		  si el que pescó es el jugador local.
	Cada rareza tiene su propio sonido.

	Para otros jugadores lejos de la cámara (UIConfig.Performance, más cerca
	con efectos reducidos): pasado CatchSplashOnlyDistance solo el chapuzón,
	pasado CatchHideDistance nada (los sonidos se recortan solos, ver Sounds).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Distance = require(script.Parent.Parent.Effects.Distance)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Fx = require(script.Parent.Parent.Effects.Fx)
local CatchLabels = require(script.Parent.CatchLabels)

local EFFECTS = UIConfig.Effects
local JINGLES =
	{ "CatchPop", "CatchPop", "RareCatch", "EpicCatch", "LegendaryCatch", "LegendaryCatch" }
local LABEL_FROM, TROPHY_FROM, EPIC_FROM = 2, 3, 5

local CatchShow = {}

local function headOf(character: Model): BasePart?
	local head = character:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

-- Punto de la espalda donde está la canasta (o el centro si no hay torso).
local function backOf(character: Model): Vector3
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return (torso.CFrame * CFrame.new(0, 0.3, 1.1)).Position
	end
	return character:GetPivot().Position
end

-- El pez vuela rápido a la canasta y desaparece (solo PivotTo: nada de
-- reescalar cada pieza en cada cuadro).
local function stash(model: Model, character: Model)
	local start = model:GetPivot()
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		local t = math.min(elapsed / Performance.CatchStashSeconds, 1)
		local target = backOf(character)
		model:PivotTo(CFrame.new(start.Position:Lerp(target, t)) * start.Rotation)
		if t >= 1 then
			connection:Disconnect()
			Fx.sparkle(target, UIConfig.Colors.Coins, 6)
			model:Destroy()
		end
	end)
end

function CatchShow.play(
	player: Player,
	character: Model,
	from: Vector3,
	fishId: string,
	count: number
)
	local rarity, level = FishCatalog.rarity(fishId)
	local color = UIConfig.RarityColors[rarity.id] or UIConfig.Colors.Text
	local head = headOf(character)
	if not head then
		return
	end
	local far = if player == Players.LocalPlayer
		then 0
		else Distance.fromCamera(head.Position) / Distance.scale()
	if far > Performance.CatchHideDistance then
		return
	end
	Fx.splash(from, 1.1 + level * 0.35)
	Sounds.play("Catch", from)
	Sounds.play(JINGLES[level] or "CatchPop", from, if level == 2 then 1.2 else 1)
	if far > Performance.CatchSplashOnlyDistance then
		return
	end

	local fish = FishModel.build(fishId, 1 + (level - 1) * 0.12)
	FxQuality.scaleAll(fish)
	local above = function(): CFrame
		local root = character:FindFirstChild("HumanoidRootPart")
		local facing = if root and root:IsA("BasePart") then root.CFrame.Rotation else CFrame.new()
		return CFrame.new(head.Position + Vector3.new(0, 2.4, 0))
			* facing
			* CFrame.Angles(0, math.pi / 2, 0)
	end
	local spins = if level >= TROPHY_FROM then 1 else 0
	local holdSeconds = if level >= TROPHY_FROM then EFFECTS.TrophySeconds else 0.45

	FishModel.arc(
		fish,
		from,
		above().Position,
		EFFECTS.FishJumpHeight + level,
		EFFECTS.FishJumpSeconds,
		function()
			if not character.Parent then
				fish:Destroy()
				return
			end
			if level >= LABEL_FROM then
				CatchLabels.billboard(
					head,
					rarity.displayName,
					fishId,
					count,
					color,
					holdSeconds + 0.6
				)
			end
			if level >= TROPHY_FROM then
				CatchLabels.beam(character:GetPivot().Position, color, holdSeconds, level)
				Fx.sparkle(head.Position + Vector3.new(0, 2.4, 0), color, 20 + level * 8)
			end
			if level >= EPIC_FROM then
				Fx.ring(character:GetPivot().Position - Vector3.new(0, 2.5, 0), 14, 1.4)
				if player == Players.LocalPlayer then
					CameraShake.shake(0.35, 0.5)
				end
			end
			Sounds.play("FishFlop", head.Position)
			FishModel.flop(fish, above, holdSeconds, function()
				stash(fish, character)
			end)
		end,
		spins
	)
end

return CatchShow
