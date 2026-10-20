--!strict
--[[
	ChatTags

	Etiquetas delante del nombre en el chat (TextChatService), iguales para
	todos porque cada cliente las arma con los atributos que pone el
	servidor:
		[VIP]       en oro, si tiene el pase (y el nombre también en oro)
		[TÍTULO]    su título del juego (atributo Titulo), en su color
	Ejemplo: «[VIP] [APRENDIZ] lu124ndres: hola». Solo los mensajes de
	jugadores; los del sistema quedan como vienen. TextChatService admite un
	solo OnIncomingMessage por cliente: es este.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local TextCase = require(ReplicatedStorage.Shared.TextCase)
local Titles = require(ReplicatedStorage.Shared.Titles)
local OverheadLook = require(script.Parent.OverheadLook)

local ATTR = Protocol.PlayerAttributes
local VIP_COLOR = Color3.fromRGB(255, 200, 40)

local ChatTags = {}

local function paint(text: string, color: Color3): string
	return `<font color="#{color:ToHex()}">{text}</font>`
end

-- Lo que va antes del nombre de `player` (puede quedar vacío).
local function tags(player: Player): string
	local parts = {}
	if Perks.hasPass(player, "VIP") then
		table.insert(parts, `<b>{paint("[VIP]", VIP_COLOR)}</b>`)
	end
	local value = player:GetAttribute(ATTR.Title)
	if type(value) == "number" then
		local title = TextCase.upper(Titles.name(value))
		table.insert(parts, paint(`[{title}]`, OverheadLook.mainColor(value)))
	end
	return table.concat(parts, " ")
end

function ChatTags.start()
	TextChatService.OnIncomingMessage = function(
		message: TextChatMessage
	): TextChatMessageProperties?
		local source = message.TextSource
		local player = source and Players:GetPlayerByUserId(source.UserId)
		if not player then
			return nil
		end
		local properties = Instance.new("TextChatMessageProperties")
		local name = message.PrefixText
		if Perks.hasPass(player, "VIP") then
			name = paint(name, VIP_COLOR)
		end
		local prefix = tags(player)
		properties.PrefixText = if prefix == "" then name else `{prefix} {name}`
		return properties
	end
end

return table.freeze(ChatTags)
