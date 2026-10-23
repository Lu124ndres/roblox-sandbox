--!strict
--[[
	PumpRhythm

	Entrenar en el estanque se ve como pelear un pez grande de verdad:
	bombear y recoger. En cada golpe la caña sube casi vertical con todo el
	cuerpo echado atrás (pumpUp), se congela un instante en el tope (hitstop)
	y baja recogiendo, con la mano del carrete girando (pumpDown). Cada
	HEAVE_EVERY golpes, un tirón enorme con saltito.

	Al jugador local el ritmo se lo marca el TrainingTick del servidor (beat,
	desde TrainingController), así el golpe coincide con el "+N". Los demás
	jugadores no reciben ticks: se marcan solos cada tickSeconds. Solo es
	animación: el poder lo sigue sumando el servidor igual.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local RigParts = require(script.Parent.RigParts)

type Rig = RigParts.Rig
type Pump = { rig: Rig, generation: number, count: number, lastBeat: number, startAt: number }

local TICK = Config.Gameplay.training.tickSeconds
local UP_SECONDS = 0.15
local HITSTOP_SECONDS = 0.05
local UP_DEGREES, HEAVE_DEGREES, DOWN_DEGREES = 108, 125, 62
local HEAVE_EVERY = 10
local LATE = 1.5 -- sin tick en TICK * LATE, el golpe se marca solo
local MIN_GAP = 0.25 -- dos golpes nunca más juntos que esto

local PumpRhythm = {}

local pumps: { [Player]: Pump } = {}
local loop: RBXScriptConnection? = nil

local function alive(pump: Pump): boolean
	return pump.rig.generation == pump.generation
end

local function hit(pump: Pump)
	local rig = pump.rig
	pump.count += 1
	pump.lastBeat = os.clock()
	local heave = pump.count % HEAVE_EVERY == 0
	if rig.pose then
		rig.pose.set(if heave then HEAVE_DEGREES else UP_DEGREES, UP_SECONDS, Enum.EasingStyle.Back)
	end
	if rig.body then
		rig.body.play(if heave then "heave" else "pumpUp", UP_SECONDS)
		if heave then
			rig.body.hop(0.6)
		end
	end
	task.delay(UP_SECONDS, function()
		if not alive(pump) then
			return
		end
		local down = TICK - UP_SECONDS
		if rig.pose then
			rig.pose.freeze(HITSTOP_SECONDS)
			rig.pose.set(DOWN_DEGREES, down, Enum.EasingStyle.Sine)
		end
		if rig.body then
			rig.body.hitstop(HITSTOP_SECONDS)
			rig.body.play("pumpDown", down)
		end
	end)
end

local function step()
	local now = os.clock()
	for player, pump in pumps do
		if not alive(pump) then
			pumps[player] = nil
		elseif now - pump.lastBeat >= TICK * LATE then
			hit(pump)
		end
	end
	if next(pumps) == nil and loop then
		loop:Disconnect()
		loop = nil
	end
end

-- Empieza a bombear después de `delay` segundos (lo que tarda el lanzado).
-- Se apaga solo cuando la pesca de ese jugador cambia de estado.
function PumpRhythm.start(player: Player, rig: Rig, delay: number)
	pumps[player] = {
		rig = rig,
		generation = rig.generation,
		count = 0,
		lastBeat = os.clock() + delay - TICK * LATE,
		startAt = os.clock() + delay,
	}
	if not loop then
		loop = RunService.Heartbeat:Connect(step)
	end
end

-- Llegó un tick de entrenamiento de este jugador: golpe ahora.
function PumpRhythm.beat(player: Player)
	local pump = pumps[player]
	local now = os.clock()
	if pump and alive(pump) and now >= pump.startAt and now - pump.lastBeat >= MIN_GAP then
		hit(pump)
	end
end

return PumpRhythm
