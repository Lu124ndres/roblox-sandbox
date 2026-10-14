--!strict
--[[
	ServerBoost

	Entrenamiento para todo el servidor (productos ServerBoost<n>). La primera
	compra pone x2 por Config.Monetization.serverBoost.minutes; si alguien
	compra otra mientras está activo, el tiempo vuelve a empezar y sube a x4,
	luego x8... (x2^nivel, hasta el último nivel con precio). Al vencer
	vuelve a x1. Se publica en ReplicatedStorage.Impulsos (Perks lo lee) y
	se avisa a todos quién lo subió.

	Cada compra sube un nivel desde el activo, aunque dos personas compren el
	mismo nivel a la vez (la segunda queda un nivel más arriba).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Remotes = require(script.Parent.Parent.Remotes)

local BOOST = Config.Monetization.serverBoost
local ATTR = Protocol.BoostAttributes

local ServerBoost = {}

local folder = Instance.new("Folder")
folder.Name = Protocol.BoostFolder
folder:SetAttribute(ATTR.TrainingUntil, 0)
folder:SetAttribute(ATTR.TrainingLevel, 0)
folder:SetAttribute(ATTR.BoughtBy, "")

function ServerBoost.add(buyer: Player)
	local level = math.min(Perks.serverBoostLevel() + 1, #BOOST.robux)
	folder:SetAttribute(ATTR.TrainingLevel, level)
	folder:SetAttribute(ATTR.TrainingUntil, Workspace:GetServerTimeNow() + BOOST.minutes * 60)
	folder:SetAttribute(ATTR.BoughtBy, buyer.DisplayName)
	Remotes.Notice:FireAllClients("boost", buyer.DisplayName, 2 ^ level)
end

-- La carpeta va primero en Main: Perks la busca en ReplicatedStorage.
function ServerBoost.init()
	folder.Parent = ReplicatedStorage
end

return ServerBoost
