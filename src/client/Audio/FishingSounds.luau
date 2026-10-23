--!strict
--[[
	FishingSounds

	La pesca suena por capas, como en un buen juego de pesca: cada momento
	junta el sonido principal, un detalle (el sedal, el agua) y, cuando sale
	bien, una recompensa. Lo que se repite (los toques del carrete) sube de
	tono a medida que avanza, para que se sienta que se está ganando.
		rodOut   saca la caña: silbido corto
		cast     latigazo de la caña y el sedal sale zumbando
		land     el corcho cae: plop y bloop
		bite     pica: burbuja y tirón del sedal
		reel     cada toque del carrete (solo el jugador local): clic de
		         trinquete que sube con la barra (0..1); casi llena, el carrete
		         zumba
		hook     clava el anzuelo: el carrete zumba y el pez rompe el agua
		landed   el pez le llega a la mano: un "ting" más agudo cuanto más raro
		stash    el pez entra a la canasta: golpe blando
		escape   se corta el sedal: chasquido y plop triste
	Las claves están en Assets.Sounds (bloque "Pesca"); su volumen y alcance,
	aquí con Sounds.define.
]]

local Sounds = require(script.Parent.Sounds)

local REEL_LOW, REEL_HIGH = 0.85, 1.6 -- tono del clic con la barra vacía y llena
local REEL_ZIP_FROM = 0.85 -- desde aquí cada toque suma el zumbido del carrete

Sounds.define({
	FishRodSwish = { volume = 0.5, rollOff = 70 },
	FishReelZip = { volume = 0.45, rollOff = 80 },
	FishBloop = { volume = 0.5, rollOff = 70 },
	FishLineTug = { volume = 0.6, rollOff = 60 },
	FishReelClick = { volume = 0.55 },
	FishSplash = { volume = 0.7, rollOff = 90 },
	FishLineSnap = { volume = 0.6, rollOff = 70 },
	FishBasket = { volume = 0.5, rollOff = 50 },
	FishTing = { volume = 0.45, rollOff = 70 },
})

local FishingSounds = {}

function FishingSounds.rodOut(at: Vector3)
	Sounds.play("RodOut", at)
	Sounds.play("FishRodSwish", at, 1.3, 0.5)
end

function FishingSounds.cast(at: Vector3)
	Sounds.play("Cast", at)
	Sounds.play("FishRodSwish", at)
	task.delay(0.08, Sounds.play, "FishReelZip", at, 1.1)
end

function FishingSounds.land(at: Vector3)
	Sounds.play("Plop", at)
	Sounds.play("FishBloop", at, 1.1)
end

function FishingSounds.bite(at: Vector3, rod: Vector3)
	Sounds.play("Bite", at)
	Sounds.play("FishBloop", at, 0.8, 0.8)
	Sounds.play("FishLineTug", rod)
end

-- progress: cuánto lleva la barra después del toque (0..1).
function FishingSounds.reel(progress: number)
	local p = math.clamp(progress, 0, 1)
	Sounds.play("FishReelClick", nil, REEL_LOW + (REEL_HIGH - REEL_LOW) * p)
	if p >= REEL_ZIP_FROM then
		Sounds.play("FishReelZip", nil, 1.2 + p * 0.3, 0.6)
	end
end

function FishingSounds.hook(rod: Vector3, water: Vector3)
	Sounds.play("Reel", rod)
	Sounds.play("FishReelZip", rod, 1.25)
	Sounds.play("FishSplash", water)
end

-- level: rareza (1 común .. 6 mítico).
function FishingSounds.landed(at: Vector3, level: number)
	Sounds.play("FishTing", at, 1 + (level - 1) * 0.12, 0.7 + level * 0.05, true)
end

function FishingSounds.stash(at: Vector3)
	Sounds.play("FishBasket", at)
end

function FishingSounds.escape(at: Vector3, rod: Vector3)
	Sounds.play("FishLineSnap", rod)
	Sounds.play("Escape", at)
	Sounds.play("FishBloop", at, 0.6, 0.7)
end

return table.freeze(FishingSounds)
