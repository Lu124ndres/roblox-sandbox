--!strict
--[[
	NewsService

	Anota qué actualización vio cada jugador en la ventana NOVEDADES (guardado
	newsSeenAt, atributo NovedadVistaEn), así se le abre sola una sola vez por
	actualización. El remote no lleva argumentos: cuál es la actual lo decide
	el servidor con su hora (shared/UpdateClock).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateClock = require(ReplicatedStorage.Shared.UpdateClock)
local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)

local NewsService = {}

local function mark(player: Player)
	local current = UpdateClock.current()
	local save = PlayerData.read(player)
	if not current or not save or save.newsSeenAt >= current.at then
		return
	end
	PlayerData.edit(player, function(data) -- publica el atributo NovedadVistaEn
		data.newsSeenAt = current.at
	end)
end

function NewsService.init()
	Remotes.NewsSeen.OnServerEvent:Connect(RateLimit.wrap("NewsSeen", 0.2, 2, mark))
end

return NewsService
