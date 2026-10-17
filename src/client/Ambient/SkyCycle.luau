--!strict
--[[
	SkyCycle

	Ciclo de día y noche con el reloj del servidor (GetServerTimeNow): todos
	ven el mismo cielo. El día dura más que la noche; luz, bruma y tono
	cambian: mañana, mediodía, atardecer y noche estrellada (SkyMoods).
	Encima se mezclan el ambiente del cráter (ZoneMood; con el desierto del
	minotauro, el de SkyMoods.desert según CraterMode.sandBlend) y el amanecer
	del descanso (RestDawn: al llenar al monstruo sale el sol). Lighting se
	escribe cada SkyUpdateSeconds (UIConfig.Performance) o si la hora o las
	mezclas cambian de más. Workspace.HoraFija congela la hora.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local CraterMode = require(script.Parent.CraterMode)
local RestDawn = require(script.Parent.RestDawn)
local SkyMoods = require(script.Parent.SkyMoods)
local ZoneMood = require(script.Parent.ZoneMood)

local EFFECTS = UIConfig.Effects
local DAY_SHARE = 0.75 -- fracción del ciclo que es de día (6:00 a 19:00)
local MOODS = SkyMoods.day
local DESERT = SkyMoods.desert
local DAWN = SkyMoods.dawn

type Mood = SkyMoods.Mood

local SkyCycle = {}

-- Hora del día (0..24) a partir de la fracción del ciclo.
function SkyCycle.hourAt(fraction: number): number
	if fraction < DAY_SHARE then
		return 6 + 13 * (fraction / DAY_SHARE)
	end
	return (19 + 11 * ((fraction - DAY_SHARE) / (1 - DAY_SHARE))) % 24
end

function SkyCycle.currentHour(): number
	local fixed = Workspace:GetAttribute("HoraFija")
	if type(fixed) == "number" then
		return fixed
	end
	local cycleSeconds = EFFECTS.DayCycleMinutes * 60
	local fraction = (Workspace:GetServerTimeNow() % cycleSeconds) / cycleSeconds
	return SkyCycle.hourAt(fraction)
end

-- 0 de día, 1 de noche cerrada (para luces, faro y estrellas). Con el
-- amanecer del descanso cuenta la hora que se ve (el sol ya salió).
function SkyCycle.nightness(hour: number): number
	local dawn = RestDawn.blend()
	if dawn > 0 then
		hour = (hour + ((SkyMoods.dawnHour - hour) % 24) * dawn) % 24
	end
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

local function mix(x: number, y: number, t: number): number
	return x + (y - x) * t
end

-- El ambiente del cráter: el de lava, o el del desierto mientras está la arena (hot 0..1).
local function craterMood(hot: number): Mood
	local c = SkyMoods.crater
	return {
		hour = mix(SkyMoods.craterHour, SkyMoods.desertHour, hot),
		brightness = mix(c.brightness, DESERT.brightness, hot),
		atmosphere = c.atmosphere:Lerp(DESERT.atmosphere, hot),
		decay = c.decay:Lerp(DESERT.decay, hot),
		density = mix(c.density, DESERT.density, hot),
		tint = c.tint:Lerp(DESERT.tint, hot),
		ambient = c.ambient:Lerp(DESERT.ambient, hot),
	}
end

function SkyCycle.start()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local baseSaturation = if correction then correction.Saturation else 0
	local baseContrast = if correction then correction.Contrast else 0
	local lastHour, lastZone, lastDawn, lastHot, sinceWrite = -1, -1, -1, -1, math.huge
	RunService.RenderStepped:Connect(function(dt: number)
		sinceWrite += dt
		local hour = SkyCycle.currentHour()
		local dawn = RestDawn.blend()
		-- Con el amanecer del descanso la lava pierde fuerza: manda el sol.
		local zone = ZoneMood.blend() * (1 - 0.8 * dawn)
		local hot = CraterMode.sandBlend()
		local moved = math.abs(hour - lastHour) > Performance.SkyClockStep
			or math.abs(zone - lastZone) > Performance.SkyZoneStep
			or math.abs(dawn - lastDawn) > Performance.SkyZoneStep
			or math.abs(hot - lastHot) > Performance.SkyZoneStep
		if sinceWrite < Performance.SkyUpdateSeconds and not moved then
			return
		end
		sinceWrite, lastHour, lastZone, lastDawn, lastHot = 0, hour, zone, dawn, hot
		local crater = craterMood(hot)
		local a, b, t = moodAt(hour)
		local brightness = mix(mix(a.brightness, b.brightness, t), crater.brightness, zone)
		-- En el cráter el sol va a su hora (por el camino corto); con el amanecer,
		-- avanza hacia la mañana (nunca para atrás).
		local toCrater = (crater.hour - hour + 12) % 24 - 12
		local shown = (hour + toCrater * zone) % 24
		Lighting.ClockTime = (shown + ((SkyMoods.dawnHour - shown) % 24) * dawn) % 24
		Lighting.Brightness = mix(brightness, DAWN.brightness, dawn)
		Lighting.OutdoorAmbient =
			a.ambient:Lerp(b.ambient, t):Lerp(crater.ambient, zone):Lerp(DAWN.ambient, dawn)
		if atmosphere then
			local density = mix(mix(a.density, b.density, t), crater.density, zone)
			atmosphere.Color = a.atmosphere
				:Lerp(b.atmosphere, t)
				:Lerp(crater.atmosphere, zone)
				:Lerp(DAWN.atmosphere, dawn)
			atmosphere.Decay =
				a.decay:Lerp(b.decay, t):Lerp(crater.decay, zone):Lerp(DAWN.decay, dawn)
			atmosphere.Density = mix(density, DAWN.density, dawn)
		end
		if correction then
			correction.TintColor =
				a.tint:Lerp(b.tint, t):Lerp(crater.tint, zone):Lerp(DAWN.tint, dawn)
			local saturation = mix(SkyMoods.craterSaturation, SkyMoods.desertSaturation, hot)
			local contrast = mix(SkyMoods.craterContrast, SkyMoods.desertContrast, hot)
			correction.Saturation = mix(baseSaturation, saturation, zone)
			correction.Contrast = mix(baseContrast, contrast, zone)
		end
	end)
end

return SkyCycle
