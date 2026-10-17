--!strict
--[[
	ZorroVoces

	Los sonidos de la animación del zorro al comer (claves "Zorro..." de
	Assets.Sounds, bloque Comer: Zorro). El tono sigue a la etapa: la voz de la
	cría es aguda y la de la forma final grave (VOICE); las pisadas y los
	salpicones también bajan al crecer (WEIGHT) y suenan más fuerte (LOUD).
	Con muchos peces seguidos no suena todo: cada clave espera GAP segundos
	antes de volver a sonar (el que traga, el ladrido), así una ráfaga se oye
	como un zorro comiendo con ganas y no como una ametralladora.

	Volumen y alcance: Sounds.define al cargar (no están en UIConfig.Sounds porque
	solo los usa el zorro).
]]

local Sounds = require(script.Parent.Sounds)

export type Tone = "voice" | "weight"

local VOICE = { 1.4, 1.2, 1.02, 0.88 }
local WEIGHT = { 1.25, 1.05, 0.9, 0.75 }
local LOUD = { 0.6, 0.75, 0.9, 1 }
local GAP: { [string]: number } = {
	ZorroGulp = 0.7,
	ZorroYip = 0.9,
	ZorroYipDouble = 1.2,
	ZorroLick = 1,
	ZorroPaw = 0.12,
	ZorroBubbles = 1.2,
	ZorroShimmer = 1.5,
}

Sounds.define({
	ZorroYip = { volume = 0.75, rollOff = 320 },
	ZorroYipDouble = { volume = 0.8, rollOff = 360 },
	ZorroGulp = { volume = 0.55, rollOff = 200 },
	ZorroLick = { volume = 0.45, rollOff = 160 },
	ZorroHowlJoy = { volume = 0.95, rollOff = 600 },
	ZorroHowlBig = { volume = 1.05, rollOff = 800 },
	ZorroBubbles = { volume = 0.7, rollOff = 320 },
	ZorroShimmer = { volume = 0.5, rollOff = 320 },
	ZorroPaw = { volume = 0.7, rollOff = 220 },
})

local lastPlayed: { [string]: number } = {}

local ZorroVoces = {}

-- Suena key en position con el tono de la etapa (tone) y un volumen relativo.
function ZorroVoces.play(
	key: string,
	position: Vector3,
	stage: number,
	tone: Tone?,
	volume: number?
)
	local now = os.clock()
	local gap = GAP[key]
	if gap and now - (lastPlayed[key] or -math.huge) < gap then
		return
	end
	lastPlayed[key] = now
	local s = math.clamp(stage, 1, #VOICE)
	local pitch, loud = 1, volume or 1
	if tone == "voice" then
		pitch = VOICE[s]
	elseif tone == "weight" then
		pitch, loud = WEIGHT[s], loud * LOUD[s]
	end
	Sounds.play(key, position, pitch, loud)
end

return table.freeze(ZorroVoces)
