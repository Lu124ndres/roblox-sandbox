--!strict
--[[
	FxQuality

	Aplica "efectos reducidos": baja el ritmo de las partículas que emiten
	solas (cristales, bruma, chispas), apaga los rayos de sol y la
	profundidad de campo. Recuerda el ritmo original de cada emisor en el
	atributo RitmoBase para volver a él al desactivarlo. Las ráfagas de Fx
	se achican aparte con ClientSettings.fxScale().

	No vigila cada pieza nueva del Workspace (con 40-50 jugadores eso se
	dispara miles de veces): al arrancar ajusta los emisores del mapa, y
	quien crea un emisor después llama a FxQuality.scaleEmitter(emisor).
	Al cambiar el ajuste se recorren el Workspace y los emisores
	registrados (también los que están guardados sin padre, como una caña
	guardada).

	También arranca el vigilante de cuadros por segundo (FpsWatchdog).
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ClientSettings = require(script.Parent.ClientSettings)
local FpsWatchdog = require(script.Parent.FpsWatchdog)

local BASE_ATTRIBUTE = "RitmoBase"

local FxQuality = {}

-- Débil: un emisor destruido sale solo de la lista.
local registered: { [ParticleEmitter]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function adjust(emitter: ParticleEmitter)
	local base = emitter:GetAttribute(BASE_ATTRIBUTE)
	if type(base) ~= "number" then
		base = emitter.Rate
		emitter:SetAttribute(BASE_ATTRIBUTE, base)
	end
	emitter.Rate = (base :: number) * ClientSettings.fxScale()
end

-- Multiplicador del ritmo de los emisores continuos (1 normal, menos con efectos reducidos).
function FxQuality.rateScale(): number
	return ClientSettings.fxScale()
end

-- Para quien crea un emisor continuo: lo ajusta ya y lo recuerda para
-- reajustarlo si cambia el ajuste. Llamar después de fijar su Rate.
function FxQuality.scaleEmitter(emitter: ParticleEmitter)
	registered[emitter] = true
	adjust(emitter)
end

-- Igual que scaleEmitter para todos los emisores dentro de root.
function FxQuality.scaleAll(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			FxQuality.scaleEmitter(descendant)
		end
	end
end

local function applyAll()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			adjust(descendant)
		end
	end
	for emitter in registered do
		if not emitter:IsDescendantOf(Workspace) then
			adjust(emitter)
		end
	end
	local low = ClientSettings.get("lowFx")
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") then
			effect.Enabled = not low
		end
	end
end

function FxQuality.start()
	ClientSettings.onChanged(function(key: string)
		if key == "lowFx" then
			applyAll()
		end
	end)
	applyAll()
	FpsWatchdog.start()
end

return FxQuality
