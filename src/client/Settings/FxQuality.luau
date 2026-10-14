--!strict
--[[
	FxQuality

	Aplica "efectos reducidos": baja el ritmo de todas las partículas que
	emiten solas (cristales, bruma, chispas), apaga los rayos de sol y la
	profundidad de campo. Recuerda el ritmo original de cada emisor en el
	atributo RitmoBase para volver a él al desactivarlo. Las ráfagas de Fx
	se achican aparte con ClientSettings.fxScale().
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local ClientSettings = require(script.Parent.ClientSettings)

local BASE_ATTRIBUTE = "RitmoBase"

local FxQuality = {}

local function adjust(emitter: ParticleEmitter)
	local base = emitter:GetAttribute(BASE_ATTRIBUTE)
	if type(base) ~= "number" then
		base = emitter.Rate
		emitter:SetAttribute(BASE_ATTRIBUTE, base)
	end
	emitter.Rate = (base :: number) * ClientSettings.fxScale()
end

local function applyAll()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			adjust(descendant)
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
	Workspace.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("ParticleEmitter") and ClientSettings.get("lowFx") then
			-- Al aparecer el emisor todavía no tiene su ritmo final: esperar un cuadro.
			task.defer(adjust, descendant)
		end
	end)
	ClientSettings.onChanged(function(key: string)
		if key == "lowFx" then
			applyAll()
		end
	end)
	applyAll()
end

return FxQuality
