--!strict
--[[
	Badges

	Logros del jugador (Config.Retention.badges). Cada uno se entrega una sola
	vez: se anota en sus datos (badges) y, si ya existe la insignia en Roblox
	(Assets.Badges con un ID distinto de 0), se le entrega con BadgeService.
	Siempre se avisa en el juego (Notice "badge").
]]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Remotes = require(script.Parent.Parent.Remotes)

local Badges = {}

function Badges.award(player: Player, key: string)
	local save = PlayerData.read(player)
	if not save or save.badges[key] or not Config.Retention.badges[key] then
		return
	end
	PlayerData.edit(player, function(data)
		data.badges[key] = true
	end)
	Remotes.Notice:FireClient(player, "badge", key)
	local badgeId = Assets.Badges[key]
	if badgeId and badgeId ~= 0 then
		task.spawn(function()
			local ok, err = pcall(function()
				BadgeService:AwardBadge(player.UserId, badgeId)
			end)
			if not ok then
				warn(`Badges: no se pudo entregar {key} a {player.Name}: {err}`)
			end
		end)
	end
end

return Badges
