--!strict
--[[
	OrcaMotion/Feeders

	Quién le está dando de comer al gigante ahora mismo, según los lotes de
	GiantFed que manda el servidor cada ~0.25 s mientras alguien mantiene
	E/F o el botón. Da la dirección (desde el centro del lago, en el plano)
	hacia donde está la gente que alimenta: si están repartidos por todo el
	borde, la del último que le dio.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(script.Parent.Parent.Parent.Protocol)

local HOLD_SECONDS = 1.3 -- sin lotes por este tiempo: ya no le da de comer
local SPREAD_LIMIT = 0.35 -- suma de direcciones más corta que esto: están repartidos

export type Feeders = {
	direction: () -> Vector3?,
	destroy: () -> (),
}

type Feeder = { position: Vector3, at: number }

local Feeders = {}

function Feeders.watch(origin: Vector3): Feeders
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local giantFed = remotes:WaitForChild(Protocol.Remotes.GiantFed) :: RemoteEvent
	local feeders: { [number]: Feeder } = {}
	local connection = giantFed.OnClientEvent:Connect(function(batch: unknown)
		if type(batch) ~= "table" then
			return
		end
		for _, entry in batch :: { any } do
			local userId = type(entry) == "table" and entry.userId
			local player = type(userId) == "number" and Players:GetPlayerByUserId(userId)
			local character = player and player.Character
			if player and character then
				feeders[player.UserId] =
					{ position = character:GetPivot().Position, at = os.clock() }
			end
		end
	end)

	local function direction(): Vector3?
		local sum, latest, latestAt = Vector3.zero, nil :: Vector3?, 0
		for userId, feeder in feeders do
			if os.clock() - feeder.at > HOLD_SECONDS then
				feeders[userId] = nil
				continue
			end
			local flat = Vector3.new(feeder.position.X - origin.X, 0, feeder.position.Z - origin.Z)
			if flat.Magnitude > 1 then
				sum += flat.Unit
				if feeder.at > latestAt then
					latest, latestAt = flat.Unit, feeder.at
				end
			end
		end
		return if sum.Magnitude > SPREAD_LIMIT then sum.Unit else latest
	end

	return {
		direction = direction,
		destroy = function()
			connection:Disconnect()
		end,
	}
end

return table.freeze(Feeders)
