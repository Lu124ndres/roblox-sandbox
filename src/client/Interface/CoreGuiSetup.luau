--!strict
--[[
	CoreGuiSetup

	Apaga partes de la interfaz de Roblox que estorban al HUD. La lista de
	jugadores (arriba a la derecha, sale sola porque hay leaderstats) tapaba
	los botones TIENDA y MEJORAS: solo se podía tocar el nombre. Las mismas
	cifras ya se ven en el HUD y en los tableros del mundo.
	SetCoreGuiEnabled puede fallar si Roblox aún no cargó su interfaz, por eso
	se reintenta unas veces.
]]

local StarterGui = game:GetService("StarterGui")

local ATTEMPTS = 10
local RETRY_SECONDS = 0.5

local CoreGuiSetup = {}

function CoreGuiSetup.start()
	task.spawn(function()
		for _ = 1, ATTEMPTS do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)
			if ok then
				return
			end
			task.wait(RETRY_SECONDS)
		end
	end)
end

return CoreGuiSetup
