--!strict
--[[
	CoreGuiSetup

	La tabla de jugadores de Roblox (Tab) se deja solo en computadora: ahí se
	abre apretando Tab y no tapa nada. En celular y tableta se apaga, porque
	sobre los botones de arriba a la derecha (TIENDA, MEJORAS) no se podía tocar.
	Las columnas (poder, monedas, kills, renacimientos) salen de leaderstats.
	SetCoreGuiEnabled puede fallar si Roblox aún no cargó su interfaz, por eso
	se reintenta unas veces.
]]

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local ATTEMPTS = 10
local RETRY_SECONDS = 0.5

local CoreGuiSetup = {}

function CoreGuiSetup.start()
	task.spawn(function()
		for _ = 1, ATTEMPTS do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(
					Enum.CoreGuiType.PlayerList,
					UserInputService.KeyboardEnabled
				)
			end)
			if ok then
				return
			end
			task.wait(RETRY_SECONDS)
		end
	end)
end

return CoreGuiSetup
