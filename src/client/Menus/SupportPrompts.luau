--!strict
--[[
	SupportPrompts

	Ventanas oficiales de Roblox para apoyar al juego sin salir de él:
		favorite()   agregar el juego a favoritos (AvatarEditorService con el
		             PlaceId como asset: es la forma que usan los juegos)
		joinGroup()  unirse al grupo del juego (Config.Social.group.groupId)
	Roblox no tiene ventana para dar like dentro del juego: eso se pide con el
	letrero de la meta de likes (Menus/LikeSign) y se premia con su código.
]]

local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SupportPrompts = {}

function SupportPrompts.favorite(): boolean
	local ok = pcall(
		AvatarEditorService.PromptSetFavorite,
		AvatarEditorService,
		game.PlaceId,
		Enum.AvatarItemType.Asset,
		true
	)
	return ok
end

function SupportPrompts.joinGroup(): boolean
	local groupId = Config.Social.group.groupId
	if groupId == 0 then
		return false
	end
	local ok = pcall(GroupService.PromptJoinAsync, GroupService, groupId)
	return ok
end

return SupportPrompts
