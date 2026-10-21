--!strict
--[[
	StartZoom

	En pantallas táctiles la cámara arranca más lejos del personaje que la de
	Roblox (~12.5 studs): de cerca, el cartel sobre la cabeza (Overhead) tapa
	al personaje en el teléfono. Se fuerza el zoom subiendo un momento el
	mínimo del jugador y se devuelve el que tenía, así el jugador puede
	acercarse de nuevo con los dedos. Pasa en cada aparición.
]]

local Players = game:GetService("Players")

local Device = require(script.Parent.Device)

local START_DISTANCE = 20 -- studs de la cámara al personaje al aparecer
local HOLD_SECONDS = 0.5 -- lo que dura el mínimo alto (la cámara tarda en tomarlo)

local StartZoom = {}

local function push(player: Player)
	local previous = player.CameraMinZoomDistance
	if previous >= START_DISTANCE then
		return
	end
	player.CameraMinZoomDistance = START_DISTANCE
	task.delay(HOLD_SECONDS, function()
		-- Solo si nadie más lo cambió mientras tanto.
		if player.CameraMinZoomDistance == START_DISTANCE then
			player.CameraMinZoomDistance = previous
		end
	end)
end

function StartZoom.start()
	if not Device.touch() then
		return
	end
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(function()
		push(player)
	end)
	if player.Character then
		push(player)
	end
end

return StartZoom
