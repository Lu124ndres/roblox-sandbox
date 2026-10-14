--!strict
--[[
	Punto de entrada del servidor. Solo arranca los sistemas en orden;
	cada módulo documenta su propia responsabilidad.

	Orden: plantillas de gigantes -> guardado (datos de jugador) -> gigante
	-> pesca, alimentar y entrenamiento (que dependen de los anteriores).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FeedingService = require(script.Parent.FeedingService)
local FishingService = require(script.Parent.FishingService)
local GiantCycle = require(script.Parent.GiantCycle)
local GiantMood = require(script.Parent.GiantMood)
local GiantService = require(script.Parent.GiantService)
local GiantTemplates = require(script.Parent.GiantTemplates)
local DailyReward = require(script.Parent.Retention.DailyReward)
local Leaderboards = require(script.Parent.Retention.Leaderboards)
local Milestones = require(script.Parent.Retention.Milestones)
local Passes = require(script.Parent.Monetization.Passes)
local Codes = require(script.Parent.Social.Codes)
local FriendBoost = require(script.Parent.Social.FriendBoost)
local GroupReward = require(script.Parent.Social.GroupReward)
local Receipts = require(script.Parent.Monetization.Receipts)
local SaveService = require(script.Parent.Save.SaveService)
local SettingsService = require(script.Parent.Retention.SettingsService)
local ShopService = require(script.Parent.ShopService)
local TerrainBuilder = require(script.Parent.World.TerrainBuilder)
local TrainingService = require(script.Parent.TrainingService)

local map = Workspace:WaitForChild(Protocol.Map.Root)

GiantTemplates.publish()
SaveService.init()
GiantService.init(map)
GiantMood.init()
GiantCycle.init(map)
FishingService.init()
FeedingService.init()
TrainingService.init(map)
ShopService.init(map)
Milestones.init()
DailyReward.init()
SettingsService.init()
Leaderboards.init()
Passes.init()
Receipts.init()
FriendBoost.init()
Codes.init()
GroupReward.init()
-- El terreno al final: tarda unos segundos y nada de lo anterior lo necesita (se aparece
-- en la pieza de aparición). Así EstadoGigante y los remotes existen desde el principio.
TerrainBuilder.build()
