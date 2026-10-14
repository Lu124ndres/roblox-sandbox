--!strict
--[[
	GiantOutline

	Contorno rojo del gigante: se ve amenazante incluso a lo lejos y de
	noche, late y se enciende más cuanto más enojado está
	(EstadoGigante.Anger). Se actualiza a GiantOutlineSeconds (15 Hz) y con
	efectos reducidos se apaga mientras está calmado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local ANGRY_FROM = Config.Giants.anger.angryThreshold

local GiantOutline = {}

-- Devuelve la función que lo anima; llamarla cada cuadro con dt y el tiempo total.
function GiantOutline.attach(model: Model): (dt: number, elapsed: number) -> ()
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.FillColor = Color3.fromRGB(255, 20, 10)
	outline.OutlineColor = Color3.fromRGB(255, 40, 40)
	outline.OutlineTransparency = 0.35
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)

	local since = math.huge
	return function(dt: number, elapsed: number)
		since += dt
		if since < Performance.GiantOutlineSeconds then
			return
		end
		since = 0
		local value = stateFolder:GetAttribute(Protocol.GiantAttributes.Anger)
		local anger = if type(value) == "number" then value else 0
		outline.Enabled = anger >= ANGRY_FROM or not ClientSettings.get("lowFx")
		local pulse = 0.5 + 0.5 * math.sin(elapsed * (3 + anger * 7))
		outline.OutlineTransparency = 0.35 * (1 - anger) * (1 - pulse * 0.4)
		outline.FillTransparency = 1 - anger * 0.35 * pulse
	end
end

return GiantOutline
