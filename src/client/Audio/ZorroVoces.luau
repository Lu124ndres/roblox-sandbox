--!strict
--[[
	ZorroVoces

	Los sonidos del zorro de agua (claves "Zorro..." de Assets.Sounds, bloques
	Comer: Zorro y ZorroDeAgua). Dos formas:
		play(clave, posición, etapa, tono?, volumen?)  una clave suelta (la usa
		    ZorroComerFx en su animación al comer)
		event(evento, info)  las capas de un evento (ZorroRecetas): howl, fan,
		    crouch, land, shake, happy, step, yip, whine, pounce, yawn, sniff,
		    splash y bite. Un evento sin receta no suena.
	El tono sigue a la etapa: la voz de la cría es aguda y la de la forma final
	grave (VOICE); las pisadas, salpicones y el hielo también bajan al crecer
	(WEIGHT) y suenan más fuerte (LOUD). info.ice dice si pisa un témpano (las
	capas "ice" o "water" de la receta). Cada clave con GAP espera esos
	segundos antes de volver a sonar: una ráfaga de pasos o de peces se oye
	como un zorro y no como una ametralladora.

	Volumen y alcance: Sounds.define al cargar (no están en UIConfig.Sounds porque
	solo los usa el zorro).
]]

local Sounds = require(script.Parent.Sounds)
local ZorroRecetas = require(script.Parent.ZorroRecetas)

export type Tone = "voice" | "weight"
export type Info = {
	stage: number,
	head: Vector3,
	ground: Vector3,
	body: Vector3?, -- si falta, entre la cabeza y el suelo
	ice: boolean?, -- pisa un témpano (crujido) en vez de agua (chapoteo)
	strength: number?, -- multiplica el volumen (un salto más alto, un paso más fuerte)
}

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
	ZorroStepWater = 0.1,
	ZorroIceCrack = 0.25,
	ZorroIceCrackBig = 0.6,
	ZorroIceTink = 0.4,
	ZorroYelp = 0.4,
	ZorroWhimper = 1.5,
	ZorroGrowl = 1.5,
	ZorroRumble = 2,
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
	-- ZorroDeAgua (ZorroRecetas)
	ZorroWhimper = { volume = 0.6, rollOff = 260 },
	ZorroYelp = { volume = 0.7, rollOff = 300 },
	ZorroBark = { volume = 0.75, rollOff = 400 },
	ZorroHowlYoung = { volume = 0.85, rollOff = 500 },
	ZorroHowlDeep = { volume = 1.05, rollOff = 800 },
	ZorroRumble = { volume = 0.8, rollOff = 700 },
	ZorroYawn = { volume = 0.6, rollOff = 260 },
	ZorroSniff = { volume = 0.5, rollOff = 180 },
	ZorroGrowl = { volume = 0.5, rollOff = 240 },
	ZorroBite = { volume = 0.7, rollOff = 260 },
	ZorroStepWater = { volume = 0.5, rollOff = 220 },
	ZorroSplash = { volume = 0.9, rollOff = 450 },
	ZorroSplashDeep = { volume = 1, rollOff = 600 },
	ZorroShakeSwish = { volume = 0.7, rollOff = 320 },
	ZorroDrip = { volume = 0.5, rollOff = 220 },
	ZorroTailSwish = { volume = 0.6, rollOff = 320 },
	ZorroWhoosh = { volume = 0.7, rollOff = 400 },
	ZorroIceCrack = { volume = 0.6, rollOff = 260 },
	ZorroIceCrackBig = { volume = 0.8, rollOff = 450 },
	ZorroIceTink = { volume = 0.45, rollOff = 220 },
	ZorroScream = { volume = 0.9, rollOff = 500 },
	ZorroGekker = { volume = 0.7, rollOff = 300 },
	ZorroHungry = { volume = 0.8, rollOff = 500 },
	ZorroFull = { volume = 0.6, rollOff = 260 },
})

local lastPlayed: { [string]: number } = {}

local ZorroVoces = {}

-- Tono y volumen de una capa según la etapa (tone: voz, peso o ninguno).
local function scaled(stage: number, tone: Tone?): (number, number)
	local s = math.clamp(stage, 1, #VOICE)
	if tone == "voice" then
		return VOICE[s], 1
	elseif tone == "weight" then
		return WEIGHT[s], LOUD[s]
	end
	return 1, 1
end

local function ready(key: string): boolean
	local now = os.clock()
	local gap = GAP[key]
	if gap and now - (lastPlayed[key] or -math.huge) < gap then
		return false
	end
	lastPlayed[key] = now
	return true
end

-- Suena key en position con el tono de la etapa (tone) y un volumen relativo.
function ZorroVoces.play(
	key: string,
	position: Vector3,
	stage: number,
	tone: Tone?,
	volume: number?
)
	if not ready(key) then
		return
	end
	local pitch, loud = scaled(stage, tone)
	Sounds.play(key, position, pitch, loud * (volume or 1))
end

local function playLayer(layer: ZorroRecetas.Layer, info: Info)
	if not ready(layer.key) then
		return
	end
	local pitch, loud = scaled(info.stage, layer.tone)
	local position = if layer.at == "head"
		then info.head
		elseif layer.at == "body" then info.body or info.head:Lerp(info.ground, 0.5)
		else info.ground
	local volume = loud * (layer.volume or 1) * (info.strength or 1)
	Sounds.play(layer.key, position, pitch * (layer.pitch or 1), volume)
end

local function applies(layer: ZorroRecetas.Layer, info: Info): boolean
	if layer.stages and table.find(layer.stages, info.stage) == nil then
		return false
	end
	if layer.surface == "ice" then
		return info.ice == true
	elseif layer.surface == "water" then
		return info.ice ~= true
	end
	return true
end

-- Suena el evento kind (las capas de esta etapa y este suelo). Sin receta: nada.
function ZorroVoces.event(kind: string, info: Info)
	local recipe = ZorroRecetas[kind]
	if not recipe then
		return
	end
	for _, layer in recipe do
		if applies(layer, info) then
			if layer.delay then
				task.delay(layer.delay, playLayer, layer, info)
			else
				playLayer(layer, info)
			end
		end
	end
end

-- Si el evento tiene receta (ZorroStand puede dejar el resto a ZorroComerFx).
function ZorroVoces.has(kind: string): boolean
	return ZorroRecetas[kind] ~= nil
end

return table.freeze(ZorroVoces)
