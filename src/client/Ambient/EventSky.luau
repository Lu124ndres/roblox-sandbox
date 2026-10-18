--!strict
--[[
	EventSky

	El cielo de los eventos del servidor (Config/Events): mientras hay uno, el
	cielo entero cambia de color para que se note desde cualquier lado y se
	sepa cuál es (pedido del usuario, 2026-10-18):
		PescaDorada    atardecer dorado (17:30), luz de miel
		Frenesi        tarde eléctrica turquesa, cielo cargado (los relámpagos
		               son de EventFx)
		LluviaMonedas  amanecer naranja y rosado
		PoderDoble     noche violeta (la aurora es de EventFx)
	SkyCycle mezcla este ambiente encima de todo (hora, cráter, amanecer del
	descanso) con `mixInto`; entra y sale suave (FADE_SECONDS). En el cráter
	pesa un poco menos, para que se siga viendo el hábitat del monstruo.
	Arranca también EventFx (los efectos en el mundo de cada evento).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ServerEvents = require(ReplicatedStorage.Shared.ServerEvents)
local EventFx = require(script.Parent.EventFx)

-- Lo de SkyMoods más la bruma (Haze) y el resplandor (Glare) de Atmosphere, que
-- pintan el cielo entero del color del evento (SkyCycle no los toca).
type EventMood = {
	hour: number,
	brightness: number,
	atmosphere: Color3,
	decay: Color3,
	density: number,
	tint: Color3,
	ambient: Color3,
	haze: number,
	glare: number,
}

local FADE_SECONDS = 2.5
local STRENGTH = 0.85 -- cuánto manda el cielo del evento (1 = todo)
local CRATER_SHARE = 0.6 -- en el cráter, la fuerza se multiplica por esto

local rgb = Color3.fromRGB
local MOODS: { [string]: EventMood } = {
	PescaDorada = {
		hour = 17.5,
		brightness = 2.6,
		atmosphere = rgb(255, 196, 90),
		decay = rgb(255, 140, 40),
		density = 0.36,
		tint = rgb(255, 225, 165),
		ambient = rgb(170, 130, 70),
		haze = 2.6,
		glare = 1.6,
	},
	Frenesi = {
		hour = 14,
		brightness = 1.7,
		atmosphere = rgb(90, 230, 255),
		decay = rgb(20, 80, 170),
		density = 0.42,
		tint = rgb(185, 240, 255),
		ambient = rgb(60, 120, 150),
		haze = 2.4,
		glare = 0.4,
	},
	LluviaMonedas = {
		hour = 6.8,
		brightness = 2.4,
		atmosphere = rgb(255, 170, 120),
		decay = rgb(255, 110, 80),
		density = 0.34,
		tint = rgb(255, 220, 190),
		ambient = rgb(170, 120, 90),
		haze = 2.4,
		glare = 1.2,
	},
	PoderDoble = {
		hour = 21.5,
		brightness = 1.6,
		atmosphere = rgb(170, 110, 255),
		decay = rgb(70, 20, 140),
		density = 0.38,
		tint = rgb(220, 195, 255),
		ambient = rgb(110, 80, 170),
		haze = 2.2,
		glare = 0.6,
	},
}

local EventSky = {}

local blend = 0
local baseHaze: number?, baseGlare: number? = nil, nil -- los de Atmosphere sin evento
local current: string? = nil -- el evento que se ve (sigue mientras se desvanece)

function EventSky.blend(): number
	return blend
end

function EventSky.current(): string?
	return if blend > 0 then current else nil
end

local function mix(x: number, y: number, t: number): number
	return x + (y - x) * t
end

-- Lleva lo que SkyCycle acaba de escribir hacia el cielo del evento. `crater` es
-- cuánto está la cámara en el cráter (0..1).
function EventSky.mixInto(
	lighting: Lighting,
	atmosphere: Atmosphere?,
	correction: ColorCorrectionEffect?,
	crater: number
)
	local mood = current and MOODS[current]
	if not mood or blend <= 0 then
		if atmosphere and baseHaze then -- el evento terminó: la bruma vuelve a la de siempre
			atmosphere.Haze, atmosphere.Glare = baseHaze, baseGlare :: number
			baseHaze, baseGlare = nil, nil
		end
		return
	end
	local t = blend * STRENGTH * mix(1, CRATER_SHARE, crater)
	local hour = lighting.ClockTime
	local toEvent = (mood.hour - hour + 12) % 24 - 12 -- por el camino corto
	lighting.ClockTime = (hour + toEvent * t) % 24
	lighting.Brightness = mix(lighting.Brightness, mood.brightness, t)
	lighting.OutdoorAmbient = lighting.OutdoorAmbient:Lerp(mood.ambient, t)
	if atmosphere then
		baseHaze = baseHaze or atmosphere.Haze
		baseGlare = baseGlare or atmosphere.Glare
		atmosphere.Haze = mix(baseHaze :: number, mood.haze, t)
		atmosphere.Glare = mix(baseGlare :: number, mood.glare, t)
		atmosphere.Color = atmosphere.Color:Lerp(mood.atmosphere, t)
		atmosphere.Decay = atmosphere.Decay:Lerp(mood.decay, t)
		atmosphere.Density = mix(atmosphere.Density, mood.density, t)
	end
	if correction then
		correction.TintColor = correction.TintColor:Lerp(mood.tint, t)
	end
end

function EventSky.start()
	RunService.Heartbeat:Connect(function(dt: number)
		local active = ServerEvents.active()
		local id = active and active.id
		if id and id ~= current then
			-- Uno nuevo: si se ve otro, primero se apaga ese y después entra este.
			if blend <= 0 or current == nil then
				current = id
			end
		end
		local target = if id and id == current then 1 else 0
		blend = math.clamp(blend + (if target > blend then dt else -dt) / FADE_SECONDS, 0, 1)
		if blend <= 0 and target == 0 then
			current = id
		end
	end)
	EventFx.start(function(): (string?, number)
		return EventSky.current(), blend
	end)
end

return EventSky
