--!strict
--[[
	BodyPose

	Mueve el cuerpo entero por código, sin animaciones subidas, para pescar,
	entrenar y alimentar: el tronco, la cabeza, los brazos y las piernas
	persiguen una pose de BodyPoses con resortes (Shared.Resorte). Cada grupo
	llega a su tiempo, como en un lanzamiento de verdad: primero las piernas,
	después el tronco, después los brazos y al final la cabeza, que se pasa un
	poco y se acomoda. Se suma a lo que dejó el Animator, así que caminar sigue
	funcionando debajo.

	Hay una sola pose por personaje (la comparten la pesca y la alimentación)
	y un solo bucle para todos. Solo se mueven los jugadores en nivel "near"
	(Effects/Distance); los demás quedan con la pose de Roblox.

	hitstop(s) congela el cuerpo s segundos en el golpe y después lo deja ir
	al doble de velocidad otros s segundos: termina el movimiento a la misma
	hora que sin congelar (no cambia ningún tiempo de la pesca).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resorte = require(ReplicatedStorage.Shared.Resorte)
local Distance = require(script.Parent.Parent.Effects.Distance)
local BodyPoses = require(script.Parent.BodyPoses)
local BodyRig = require(script.Parent.BodyRig)

export type BodyPose = {
	play: (pose: string, seconds: number) -> (), -- llega a la pose en ~seconds
	hitstop: (seconds: number) -> (),
	hop: (studs: number) -> (), -- saltito: sube y vuelve
	value: (channel: string) -> number, -- grados actuales de un canal
}

type State = {
	rig: BodyRig.BodyRig,
	player: Player?,
	springs: { [string]: Resorte.Resorte },
	target: BodyPoses.Pose,
	hz: number,
	frozen: number,
	catchUp: number,
	elapsed: number,
	api: BodyPose,
}

-- Canal -> grupo. El grupo decide qué tan rápido llega y cuánto rebota.
local CHANNELS = {
	crouch = "legs",
	spread = "legs",
	stagger = "legs",
	hop = "hop",
	waistX = "spine",
	waistY = "spine",
	waistZ = "spine",
	lShoulderX = "arms",
	lShoulderZ = "arms",
	lElbow = "arms",
	rShoulderX = "arms",
	rShoulderZ = "arms",
	rElbow = "arms",
	neckX = "neck",
	neckY = "neck",
}
local SPEED = { legs = 1.3, spine = 1.12, arms = 1, neck = 0.8, hop = 1.2 }
local DAMPING = { legs = 0.75, spine = 0.6, arms = 0.5, neck = 0.42, hop = 0.35 }
-- Con amortiguación ~0.5 un resorte llega por primera vez al objetivo en PEAK / hz segundos.
local PEAK = 0.6
local SETTLED = 0.05

local BodyPose = {}

local states: { [Model]: State } = {}
local loop: RBXScriptConnection? = nil

local values: { [string]: number } = {}

local function step(dt: number)
	for character, state in states do
		local player = state.player
		if player and Distance.tier(player) ~= "near" then
			continue
		end
		local h = dt
		if state.frozen > 0 then
			state.frozen -= dt
			h = 0
		elseif state.catchUp > 0 then
			state.catchUp -= dt
			h = dt * 2
		end
		state.elapsed += h
		local moving = false
		for name, group in CHANNELS do
			local spring = Resorte.get(state.springs, name)
			local target = state.target[name] or 0
			if h > 0 then
				Resorte.step(spring, target, h, state.hz * SPEED[group], DAMPING[group])
			end
			values[name] = spring.x
			moving = moving or math.abs(spring.x) > SETTLED or math.abs(spring.v) > SETTLED
		end
		if not moving and next(state.target) == nil then
			continue -- en reposo: no se toca nada
		end
		local t = state.elapsed
		local breath = state.target.breath or 0
		values.waistX += math.sin(t * 2.2) * 1.6 * breath
		values.neckX -= math.sin(t * 2.2 - 0.6) * 1.2 * breath
		local reel = state.target.reel or 0
		values.lShoulderX += math.sin(t * 17) * 9 * reel
		values.lElbow += math.cos(t * 17) * 14 * reel
		if character.Parent then
			BodyRig.apply(state.rig, values)
		end
	end
end

local function create(character: Model): State?
	local rig = BodyRig.find(character)
	if not rig then
		return nil
	end
	local state: State
	local api: BodyPose = {
		play = function(pose: string, seconds: number)
			state.target = BodyPoses[pose] or BodyPoses.rest
			state.hz = PEAK / math.max(seconds, 0.05)
		end,
		hitstop = function(seconds: number)
			state.frozen = seconds
			state.catchUp = seconds
		end,
		hop = function(studs: number)
			local spring = Resorte.get(state.springs, "hop")
			spring.v += studs * 2 * math.pi * state.hz * SPEED.hop * 1.6
		end,
		value = function(channel: string): number
			local spring = state.springs[channel]
			return if spring then spring.x else 0
		end,
	}
	state = {
		rig = rig,
		player = Players:GetPlayerFromCharacter(character),
		springs = {},
		target = BodyPoses.rest,
		hz = 2,
		frozen = 0,
		catchUp = 0,
		elapsed = 0,
		api = api,
	}
	return state
end

-- La pose del cuerpo de este personaje (se crea la primera vez). nil en R6.
function BodyPose.get(character: Model): BodyPose?
	local state = states[character]
	if state then
		return state.api
	end
	local created = create(character)
	if not created then
		return nil
	end
	states[character] = created
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(game) then
			states[character] = nil
		end
	end)
	if not loop then
		-- PreSimulation: después del Animator, igual que ArmPose.
		loop = RunService.PreSimulation:Connect(step)
	end
	return created.api
end

return BodyPose
