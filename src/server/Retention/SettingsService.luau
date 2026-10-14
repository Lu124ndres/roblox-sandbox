--!strict
--[[
	SettingsService

	Guarda los ajustes del jugador (música, sonidos, temblor de cámara,
	efectos reducidos). Solo se aceptan las claves conocidas y valores
	booleanos; el resto se ignora.
]]

local PlayerData = require(script.Parent.Parent.PlayerData)
local RateLimit = require(script.Parent.Parent.RateLimit)
local Remotes = require(script.Parent.Parent.Remotes)

local SettingsService = {}

local function save(player: Player, incoming: unknown)
	if type(incoming) ~= "table" then
		return
	end
	local values = incoming :: { [string]: unknown }
	PlayerData.edit(player, function(data)
		local settings = data.settings :: { [string]: boolean }
		for key in settings do
			local value = values[key]
			if type(value) == "boolean" then
				settings[key] = value
			end
		end
	end)
end

function SettingsService.init()
	Remotes.SaveSettings.OnServerEvent:Connect(RateLimit.wrap("SaveSettings", 2, 4, save))
end

return SettingsService
