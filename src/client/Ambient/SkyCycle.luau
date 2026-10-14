--!strict
--[[
	SkyCycle

	Ciclo de día y noche. La hora sale del reloj del servidor
	(GetServerTimeNow), así que todos los jugadores ven el mismo cielo sin
	que el servidor mande nada. El día dura más que la noche, y la luz, la
	bruma y el tono cambian por momentos: mañana, mediodía, atardecer y
	noche estrellada.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ZoneMood = require(script.Parent.ZoneMood)

local EFFECTS = UIConfig.Effects
local DAY_SHARE = 0.75 -- fracción del ciclo que es de día (6:00 a 19:00)

type Mood = {
	hour: number,
	brightness: number,
	atmosphere: Color3,
	decay: Color3,
	density: number,
	tint: Color3,
	ambient: Color3,
}

-- Momentos del día; entre dos momentos se interpola.
local MOODS: { Mood } = {
	{
		hour = 0,
		brightness = 1.2,
		atmosphere = Color3.fromRGB(70, 82, 130),
		decay = Color3.fromRGB(24, 30, 60),
		density = 0.34,
		tint = Color3.fromRGB(200, 214, 255),
		ambient = Color3.fromRGB(80, 90, 130),
	},
	{
		hour = 5.6,
		brightness = 1.4,
		atmosphere = Color3.fromRGB(110, 110, 160),
		decay = Color3.fromRGB(60, 50, 90),
		density = 0.34,
		tint = Color3.fromRGB(220, 214, 255),
		ambient = Color3.fromRGB(100, 100, 140),
	},
	{
		hour = 6.8,
		brightness = 1.9,
		atmosphere = Color3.fromRGB(255, 196, 170),
		decay = Color3.fromRGB(200, 120, 110),
		density = 0.32,
		tint = Color3.fromRGB(255, 236, 222),
		ambient = Color3.fromRGB(150, 130, 130),
	},
	{
		hour = 9,
		brightness = 2.2,
		atmosphere = Color3.fromRGB(200, 222, 238),
		decay = Color3.fromRGB(108, 143, 174),
		density = 0.28,
		tint = Color3.fromRGB(255, 251, 245),
		ambient = Color3.fromRGB(116, 118, 130),
	},
	{
		hour = 16.5,
		brightness = 2.2,
		atmosphere = Color3.fromRGB(200, 222, 238),
		decay = Color3.fromRGB(108, 143, 174),
		density = 0.28,
		tint = Color3.fromRGB(255, 251, 245),
		ambient = Color3.fromRGB(116, 118, 130),
	},
	{
		hour = 18.4,
		brightness = 1.8,
		atmosphere = Color3.fromRGB(255, 176, 130),
		decay = Color3.fromRGB(196, 96, 92),
		density = 0.33,
		tint = Color3.fromRGB(255, 226, 205),
		ambient = Color3.fromRGB(160, 120, 120),
	},
	{
		hour = 19.6,
		brightness = 1.4,
		atmosphere = Color3.fromRGB(120, 96, 150),
		decay = Color3.fromRGB(60, 40, 80),
		density = 0.34,
		tint = Color3.fromRGB(214, 206, 255),
		ambient = Color3.fromRGB(100, 92, 130),
	},
	{
		hour = 24,
		brightness = 1.2,
		atmosphere = Color3.fromRGB(70, 82, 130),
		decay = Color3.fromRGB(24, 30, 60),
		density = 0.34,
		tint = Color3.fromRGB(200, 214, 255),
		ambient = Color3.fromRGB(80, 90, 130),
	},
}

-- Ambiente del cráter: se mezcla encima del momento del día según ZoneMood.
local CRATER: Mood = {
	hour = 0,
	brightness = 1.1,
	atmosphere = Color3.fromRGB(90, 34, 40),
	decay = Color3.fromRGB(40, 10, 18),
	density = 0.5,
	tint = Color3.fromRGB(255, 196, 196),
	ambient = Color3.fromRGB(110, 60, 70),
}
local CRATER_SATURATION = -0.25
local CRATER_CONTRAST = 0.2

local SkyCycle = {}

-- Hora del día (0..24) a partir de la fracción del ciclo.
function SkyCycle.hourAt(fraction: number): number
	if fraction < DAY_SHARE then
		return 6 + 13 * (fraction / DAY_SHARE)
	end
	return (19 + 11 * ((fraction - DAY_SHARE) / (1 - DAY_SHARE))) % 24
end

function SkyCycle.currentHour(): number
	local cycleSeconds = EFFECTS.DayCycleMinutes * 60
	local fraction = (Workspace:GetServerTimeNow() % cycleSeconds) / cycleSeconds
	return SkyCycle.hourAt(fraction)
end

-- 0 de día, 1 de noche cerrada (para luces, faro y estrellas).
function SkyCycle.nightness(hour: number): number
	if hour >= 7 and hour <= 18 then
		return 0
	elseif hour > 18 and hour < 20 then
		return (hour - 18) / 2
	elseif hour >= 5 and hour < 7 then
		return 1 - (hour - 5) / 2
	end
	return 1
end

local function moodAt(hour: number): (Mood, Mood, number)
	for index = 1, #MOODS - 1 do
		local a, b = MOODS[index], MOODS[index + 1]
		if hour >= a.hour and hour <= b.hour then
			return a, b, (hour - a.hour) / (b.hour - a.hour)
		end
	end
	return MOODS[1], MOODS[1], 0
end

function SkyCycle.start()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local baseSaturation = if correction then correction.Saturation else 0
	local baseContrast = if correction then correction.Contrast else 0
	RunService.RenderStepped:Connect(function()
		local hour = SkyCycle.currentHour()
		local a, b, t = moodAt(hour)
		local zone = ZoneMood.blend()
		local brightness = a.brightness + (b.brightness - a.brightness) * t
		Lighting.ClockTime = hour
		Lighting.Brightness = brightness + (CRATER.brightness - brightness) * zone
		Lighting.OutdoorAmbient = a.ambient:Lerp(b.ambient, t):Lerp(CRATER.ambient, zone)
		if atmosphere then
			local density = a.density + (b.density - a.density) * t
			atmosphere.Color = a.atmosphere:Lerp(b.atmosphere, t):Lerp(CRATER.atmosphere, zone)
			atmosphere.Decay = a.decay:Lerp(b.decay, t):Lerp(CRATER.decay, zone)
			atmosphere.Density = density + (CRATER.density - density) * zone
		end
		if correction then
			correction.TintColor = a.tint:Lerp(b.tint, t):Lerp(CRATER.tint, zone)
			correction.Saturation = baseSaturation + (CRATER_SATURATION - baseSaturation) * zone
			correction.Contrast = baseContrast + (CRATER_CONTRAST - baseContrast) * zone
		end
	end)
end

return SkyCycle
