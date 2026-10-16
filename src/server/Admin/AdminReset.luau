--!strict
--[[
	Admin/AdminReset

	Deja a un jugador como recién llegado (para probar el juego desde cero):
		progress  todo a cero, pero conserva lo comprado con Robux (estanques,
		          mejoras x2, pack de inicio, pases regalados) y sus ajustes
		all       como una cuenta nueva: solo quedan los recibos de compras
		          (para que ninguna compra se cobre ni se entregue dos veces)
	Los pases comprados de verdad no se tocan (son de Roblox). También limpia lo
	que vive fuera del guardado (paso del tutorial, misiones publicadas, regalos
	por tiempo, reloj del grupo), lo hace reaparecer y guarda al momento.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Tutorial = require(script.Parent.Parent.Retention.Tutorial)
local SaveSchema = require(script.Parent.Parent.Save.SaveSchema)
local SaveService = require(script.Parent.Parent.Save.SaveService)

export type Mode = "progress" | "all"

local ATTR = Protocol.PlayerAttributes
local KEEP: { [Mode]: { string } } = {
	progress = { "receipts", "ponds", "levels", "starterPack", "gifts", "settings" },
	all = { "receipts" },
}

local AdminReset = {}

function AdminReset.run(player: Player, mode: Mode): string
	local before = PlayerData.read(player)
	assert(before, "todavía no cargó sus datos")
	local oldGifts = table.clone(before.gifts)
	PlayerData.edit(player, function(save)
		local data = save :: any
		local fresh = SaveSchema.default() :: any
		for _, key in KEEP[mode] do
			fresh[key] = data[key]
		end
		for key in fresh do
			data[key] = fresh[key]
		end
	end)
	local save = PlayerData.read(player) :: SaveSchema.SaveData
	-- Lo que el guardado nuevo ya no tiene (publicar solo pone lo que hay).
	for key in oldGifts do
		if not save.gifts[key] then
			player:SetAttribute(`{ATTR.PassPrefix}{key}`, nil)
		end
	end
	for index in Config.Progression.ponds do
		if not save.ponds[tostring(index)] then
			player:SetAttribute(`{ATTR.PondPrefix}{index}`, nil)
		end
	end
	Tutorial.forget(player)
	local now = Workspace:GetServerTimeNow()
	player:SetAttribute(ATTR.TutorialCount, 0)
	player:SetAttribute(ATTR.Quests, nil) -- Quests las vuelve a publicar del guardado nuevo
	player:SetAttribute(ATTR.PlaytimeSince, now)
	player:SetAttribute(ATTR.PlaytimeClaimed, 0)
	player:SetAttribute(ATTR.JoinedAt, now)
	task.spawn(function()
		if player.Parent == Players then
			player:LoadCharacterAsync()
		end
		SaveService.saveNow(player)
	end)
	return if mode == "all"
		then "Reiniciado como cuenta nueva"
		else "Progreso reiniciado (conserva compras y ajustes)"
end

return table.freeze(AdminReset)
