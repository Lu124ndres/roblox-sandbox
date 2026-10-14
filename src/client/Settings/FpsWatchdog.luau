--!strict
--[[
	FpsWatchdog

	Si el juego va lento (promedio por debajo de FpsWatchdogMin durante
	FpsWatchdogSeconds seguidos), activa los efectos reducidos solo por esta
	sesión: no se guarda, y el jugador lo puede volver a apagar en Ajustes.
	Una sola vez por sesión y sin avisos pesados. No mide los primeros
	segundos, mientras el juego termina de cargar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local ClientSettings = require(script.Parent.ClientSettings)

local FpsWatchdog = {}

function FpsWatchdog.start()
	local since = os.clock()
	local frames, window = 0, 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if os.clock() - since < Performance.FpsWatchdogGraceSeconds then
			return
		end
		if ClientSettings.get("lowFx") then
			frames, window = 0, 0 -- ya está reducido: se vuelve a medir si lo apaga
			return
		end
		frames += 1
		window += dt
		if window < Performance.FpsWatchdogSeconds then
			return
		end
		local average = frames / window
		frames, window = 0, 0
		if average < Performance.FpsWatchdogMin then
			connection:Disconnect()
			ClientSettings.setAutomatic("lowFx", true)
		end
	end)
end

return FpsWatchdog
