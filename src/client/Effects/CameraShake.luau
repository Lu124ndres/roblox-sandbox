--!strict
--[[
	CameraShake

	Sacude la cámara del jugador local un momento (rugidos y saltos del
	gigante). Se suma a la cámara de Roblox justo después de que ella se
	actualiza, así que no pelea con el control del jugador.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local BIND_NAME = "SacudidaDeCamara"

local CameraShake = {}

local intensity = 0
local remaining = 0
local total = 1
local bound = false

-- Sacude con fuerza "magnitude" (studs) durante "seconds"; se apaga suave.
function CameraShake.shake(magnitude: number, seconds: number)
	if not ClientSettings.get("shake") then
		return
	end
	intensity = math.max(intensity * remaining / total, magnitude)
	remaining, total = seconds, seconds
	if bound then
		return
	end
	bound = true
	RunService:BindToRenderStep(
		BIND_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		function(dt: number)
			remaining -= dt
			local camera = Workspace.CurrentCamera
			if remaining <= 0 or not camera then
				RunService:UnbindFromRenderStep(BIND_NAME)
				bound = false
				return
			end
			local strength = intensity * (remaining / total)
			local t = os.clock() * 30
			local offset = Vector3.new(math.noise(t, 1), math.noise(t, 2), math.noise(t, 3))
				* strength
			camera.CFrame *= CFrame.new(offset) * CFrame.Angles(
				0,
				0,
				math.rad(math.noise(t, 4) * strength)
			)
		end
	)
end

return CameraShake
