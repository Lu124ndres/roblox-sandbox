--!strict
--[[
	DragonCues

	Los momentos del dragón (cues de Dragon/Fx y los propios del reposo) hechos
	sonido (Audio/DragonVoces, por etapa) y efecto, para un dragón:
		roar             rugido, temblor de cámara cerca, vaho caliente y brasas
		fireStart/End    la llama sostenida suena en bucle (Audio/DragonLoops);
		                 al terminar, humo negro por la boca
		fireSky          fuego al cielo: sonido de ola de fuego y temblor
		takeoff          aletazo enorme: el aire barre la roca, anillo de aire,
		                 brasas si hay lava debajo (Effects/DragonDust)
		land             golpe en la roca: ceniza, esquirlas, chispas, anillo
		flap/hover       aletazo (más grave y fuerte al crecer); cerca del suelo o
		                 de la lava levanta polvo o brasas
		idle/wake/preen  resoplido de humo por la nariz (Effects/DragonSmoke)
		sleep/snore      ronquido en bucle mientras duerme e hilos de humo
		fold, stretch, whoosh, evolve, growl: solo sonido
	Un cue desconocido no hace nada. En las etapas grandes salen brasas de las
	grietas del cuerpo (Effects/DragonEmbers). Todo respeta volumen, alcance y
	modo rápido; destroy() corta los bucles y quita las brasas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dragon = require(ReplicatedStorage.Shared.Dragon)
local DragonFx = require(ReplicatedStorage.Shared.Dragon.Fx)
local DragonLoops = require(script.Parent.Parent.Audio.DragonLoops)
local DragonVoces = require(script.Parent.Parent.Audio.DragonVoces)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local DragonDust = require(script.Parent.Parent.Effects.DragonDust)
local DragonEmbers = require(script.Parent.Parent.Effects.DragonEmbers)
local DragonKit = require(script.Parent.Parent.Effects.DragonKit)
local DragonSmoke = require(script.Parent.Parent.Effects.DragonSmoke)
local DragonReposo = require(script.Parent.DragonReposo)
local DragonSuelo = require(script.Parent.DragonSuelo)

local SHAKE_REACH = 260
local SKY_OVERLAP = 0.5 -- segundos
local GUST_HEIGHT = 0.9 -- un aletazo levanta polvo si está a menos de esto (en largos) del suelo
local NOSE_SMOKE: { [string]: boolean } = { idle = true, wake = true, preen = true }

export type Cues = {
	cue: (kind: string, cue: DragonFx.Cue) -> (),
	step: (dt: number) -> (),
	destroy: () -> (),
}

type Place = {
	head: Vector3,
	mouth: Vector3,
	forward: Vector3,
	below: DragonSuelo.Below,
	scale: number,
	length: number,
}

local DragonCues = {}

local function shake(position: Vector3, magnitude: number, seconds: number)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local near = 1 - (character:GetPivot().Position - position).Magnitude / SHAKE_REACH
	if near > 0 then
		CameraShake.shake(magnitude * near, seconds)
	end
end

local function placeOf(motion: Dragon.Motion): Place
	local head, mouth = motion.top(), motion.mouth()
	local forward = mouth - head
	local length = motion.state.length
	return {
		head = head,
		mouth = mouth,
		forward = if forward.Magnitude > 1e-3 then forward.Unit else Vector3.yAxis,
		below = DragonSuelo.below(motion),
		scale = DragonKit.scale(length),
		length = length,
	}
end

-- Lo que se ve con cada momento (el sonido va aparte, en DragonVoces).
local function visual(kind: string, p: Place, strength: number)
	local L, s, ground = p.length, p.scale, p.below.position
	if kind == "roar" then
		shake(p.head, 0.3 + L * 0.006, 1.6)
		DragonSmoke.roar(p.mouth, p.forward, 0.6 * s)
	elseif kind == "fireEnd" then
		DragonSmoke.black(p.mouth, p.forward, 0.8 * s)
	elseif kind == "fireSky" then
		shake(p.head, 0.2 + L * 0.004, 1.2)
	elseif kind == "takeoff" then
		DragonDust.takeoff(ground, s, L * 0.6, p.below.lava)
		shake(ground, 0.15 + L * 0.004, 0.8)
	elseif kind == "land" then
		DragonDust.land(ground, s, L * 0.5, p.below.lava)
		shake(ground, 0.25 + L * 0.006, 0.7)
	elseif kind == "flap" or kind == "hover" then
		if p.below.height < L * GUST_HEIGHT then
			DragonDust.gust(ground, s * strength, p.below.lava)
		end
	elseif NOSE_SMOKE[kind] then
		DragonSmoke.nostrils(p.mouth, p.forward, 0.5 * s)
	elseif kind == "sleep" or kind == "snore" then
		DragonSmoke.wisp(p.mouth, 0.5 * s)
	end
end

function DragonCues.new(motion: Dragon.Motion): Cues
	local loops = DragonLoops.new()
	local reposo = DragonReposo.new()
	local embers: DragonEmbers.Embers? = nil
	local boundTo: any = nil
	local stage = 1
	local firing = false
	local skyAt = -math.huge -- el fuego al cielo ya suena: su arranque no repite

	local function cue(kind: string, c: DragonFx.Cue)
		DragonReposo.event(reposo, kind)
		if kind == "fireSky" then
			skyAt = os.clock()
		elseif kind == "fireStart" then
			firing = true
		elseif kind == "fireEnd" then
			firing = false
		end
		if motion.state.hidden then
			return
		end
		if kind == "fireStart" and os.clock() - skyAt < SKY_OVERLAP then
			return
		end
		local p = placeOf(motion)
		local strength = c.strength or 1
		DragonVoces.play(kind, {
			stage = c.stage,
			voice = c.voice,
			strength = c.strength,
			head = p.head,
			mouth = p.mouth,
			body = motion.state.center,
			ground = p.below.position,
		})
		visual(kind, p, strength)
	end

	local function step(dt: number)
		local state = motion.state
		local rig = state.rig
		if rig ~= boundTo then
			if embers then
				DragonEmbers.destroy(embers)
			end
			boundTo, stage = rig, DragonFx.stage(rig)
			embers = if rig then DragonEmbers.build(rig, stage, state.length) else nil
		end
		if embers then
			DragonEmbers.show(embers, not state.hidden)
		end
		local own = DragonReposo.step(reposo, dt, state.velocity.Magnitude)
		if own then
			cue(own, { stage = stage, voice = state.voice, length = state.length })
		end
		local pitch, volume = DragonVoces.weight(stage)
		loops.update("DragonFireLoop", firing and not state.hidden, motion.mouth(), pitch, volume)
		local sleeping = reposo.mode == "sleep" and not state.hidden
		loops.update("DragonSnore", sleeping, motion.top(), state.voice, 1)
	end

	return {
		cue = cue,
		step = step,
		destroy = function()
			loops.destroy()
			if embers then
				DragonEmbers.destroy(embers)
				embers = nil
			end
		end,
	}
end

return table.freeze(DragonCues)
