--!strict
--[[
	FeedThrow

	Cuando alguien alimenta al gigante, todos ven sus peces volar en arco
	desde el jugador hasta la boca, de 1 en 1 (el servidor manda un GiantFed
	por pez, con su especie). Al llegar se llama onArrive: ahí el gigante
	muerde (ver GiantView). Solo efecto visual.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Fx = require(script.Parent.Parent.Effects.Fx)

local EFFECTS = UIConfig.Effects
local BITE_SECONDS = 0.45

local FeedThrow = {}

local rng = Random.new()

-- Un pez (de la especie entregada) vuela girando desde la mano hasta la boca.
function FeedThrow.throw(from: Vector3, to: Vector3, fishId: string, onArrive: () -> ())
	local distance = (to - from).Magnitude
	local height = math.clamp(distance * 0.3, 6, 40)
	Sounds.play("Whoosh", from, rng:NextNumber(0.9, 1.15))
	local model = FishModel.build(if FishCatalog.get(fishId) then fishId else "Sardina", 1.4)
	model.Parent = Workspace
	local spread = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
	FishModel.arc(
		model,
		from + Vector3.new(0, 2, 0),
		to + spread,
		height,
		EFFECTS.FeedThrowSeconds,
		function()
			model:Destroy()
			Fx.sparkle(to + spread, UIConfig.Colors.Coins, 6)
			onArrive()
		end,
		1
	)
end

-- Escucha GiantFed (un evento por pez). getMouth da la boca del gigante (nil si
-- aún no existe). El gigante reacciona a lo sumo cada BITE_SECONDS: con muchos
-- peces seguidos se ve una mordida tras otra, no una ráfaga de efectos.
function FeedThrow.listen(getMouth: () -> Vector3?, onArrive: (character: Model) -> ())
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local giantFed = remotes:WaitForChild(Protocol.Remotes.GiantFed) :: RemoteEvent
	local lastBite = 0
	giantFed.OnClientEvent:Connect(function(feederUserId: unknown, _food: unknown, fishId: unknown)
		local feeder = if type(feederUserId) == "number"
			then Players:GetPlayerByUserId(feederUserId)
			else nil
		local character = feeder and feeder.Character
		local mouth = getMouth()
		if not character or not mouth then
			return
		end
		FeedThrow.throw(
			character:GetPivot().Position,
			mouth,
			if type(fishId) == "string" then fishId else "Sardina",
			function()
				if os.clock() - lastBite >= BITE_SECONDS then
					lastBite = os.clock()
					onArrive(character)
				end
			end
		)
	end)
end

return FeedThrow
