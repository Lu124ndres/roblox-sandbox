--!strict
--[[
	ZorroComerFx

	Sonidos y efectos de la animación del zorro al comer (Zorro/Comer). Los
	eventos que ZorroStand no conoce llegan aquí (power: rareza del pez; side:
	1 su izquierda, -1 su derecha):
		catch    gotas que saltan de la boca (GiantView ya pone el mordisco)
		gulp     traga
		slap     manotazo al agua: salpicadura bajo la pata y chapoteo
		drops    gotas de la boca al sacudir el pez
		hop      brinco: onda en el agua; hopLand: cae (salpica)
		lick     se relame
		yip      ladrido contento; thanks: le ladra al jugador que le dio el pez
		glitter  gotas y burbujas brillantes alrededor (pez raro)
		launch   despega para el salto mortal: salpicón y soplo
		joyHowl  aullido de alegría (el gran festejo: el aullido largo)
		swirl    empieza a perseguir su cola: remolino de ondas
		dash     sale corriendo; skid: frena derrapando
	El tono y el volumen de cada sonido siguen a la etapa (ZorroVoces).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Capas = require(ReplicatedStorage.Shared.Zorro.Comer.Capas)
local Zorro = require(ReplicatedStorage.Shared.Zorro)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local ZorroVoces = require(script.Parent.Parent.Audio.ZorroVoces)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ZorroGotas = require(script.Parent.Parent.Effects.ZorroGotas)

local CYAN = Color3.fromRGB(110, 255, 240)
local SHAKE_REACH = 260

local ZorroComerFx = {}

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

-- Un punto del zorro bajado al agua.
local function onWater(motion: Zorro.Motion, bone: string): Vector3
	local water = motion.water()
	local at = motion.point(bone) or motion.state.center
	return Vector3.new(at.X, water.Y, at.Z)
end

function ZorroComerFx.play(motion: Zorro.Motion, event: Zorro.Event)
	local kind, power, side = event.kind, event.power or 1, event.side or 1
	local state = motion.state
	local h = state.height
	local stage = Capas.stageFor(h)
	local size = math.max(1, h / 12)
	local below = Vector3.new(state.center.X, motion.water().Y, state.center.Z)
	if kind == "catch" then
		ZorroGotas.drops(motion.mouth(), h, power)
		ZorroVoces.play("ZorroBite", motion.mouth(), stage, "voice", 1.1)
		ZorroVoces.play("ZorroDrip", motion.mouth(), stage, "weight", 0.6)
	elseif kind == "gulp" then
		ZorroVoces.play("ZorroGulp", motion.mouth(), stage, "voice")
	elseif kind == "slap" then
		local at = onWater(motion, if side > 0 then "ManoIzq" else "ManoDer")
		Fx.splash(at, 0.7 * size)
		ZorroVoces.play("ZorroPaw", at, stage, "weight", 1.2)
	elseif kind == "drops" then
		ZorroGotas.drops(motion.mouth(), h, 1)
		ZorroVoces.play("ZorroDrip", motion.mouth(), stage, "weight", 0.6)
	elseif kind == "hop" then
		Fx.ring(below, h * 0.35, 0.8)
		ZorroVoces.play("ZorroPaw", below, stage, "weight")
	elseif kind == "hopLand" then
		Fx.splash(below, 1.1 * size)
		Fx.ring(below, h * 0.55, 1.1)
		Sounds.play("Plop", below, 0.7)
	elseif kind == "lick" then
		ZorroVoces.play("ZorroLick", motion.mouth(), stage, "voice", 0.8)
	elseif kind == "yip" then
		ZorroVoces.play("ZorroYip", motion.top(), stage, "voice")
	elseif kind == "thanks" then
		ZorroVoces.play("ZorroYipDouble", motion.top(), stage, "voice")
		Fx.sparkle(motion.top(), CYAN, 8)
	elseif kind == "glitter" then
		ZorroGotas.glitter(state.center, h, power)
		Fx.sparkle(motion.top(), CYAN, 10 + 4 * power)
		ZorroVoces.play("ZorroBubbles", motion.top(), stage, "voice", 0.8)
		if power >= 4 then
			ZorroVoces.play("ZorroShimmer", motion.top(), stage)
		end
	elseif kind == "launch" then
		Fx.splash(below, 1.8 * size)
		Fx.ring(below, h * 0.8, 1.2)
		Sounds.play("Whoosh", motion.top(), 0.8)
		shake(below, 0.25, 0.4)
	elseif kind == "joyHowl" then
		local big = power >= 6
		ZorroVoces.play(
			if big then "ZorroHowlBig" else "ZorroHowlJoy",
			motion.top(),
			stage,
			"voice"
		)
		for k = 1, if big then 4 else 2 do
			task.delay(k * 0.3, Fx.ring, below, h * (0.5 + k * 0.3), 1.5)
		end
		Fx.sparkle(motion.top(), CYAN, if big then 30 else 16)
		shake(motion.top(), if big then 0.4 else 0.2, 1.4)
	elseif kind == "swirl" then
		for k = 0, 2 do
			task.delay(k * 0.25, Fx.ring, below, h * (0.4 + k * 0.25), 1.2)
		end
		Sounds.play("Whoosh", motion.top(), 1.2, 0.7)
	elseif kind == "dash" then
		Fx.splash(onWater(motion, "PieIzq"), 1.2 * size)
		Sounds.play("Whoosh", motion.top(), 0.9)
	elseif kind == "skid" then
		Fx.splash(onWater(motion, "ManoDer"), 1.4 * size)
		Fx.splash(onWater(motion, "ManoIzq"), 1.4 * size)
		Sounds.play("BigSplash", below, 1.3, 0.8)
	end
end

-- Al correr: el chapoteo de cada pisada (ZorroVoces no deja que se amontone).
function ZorroComerFx.step(motion: Zorro.Motion)
	local state = motion.state
	if state.trail > 0.2 and state.stepped > 0 then
		local below = Vector3.new(state.center.X, motion.water().Y, state.center.Z)
		ZorroVoces.play("ZorroPaw", below, Capas.stageFor(state.height), "weight", 0.7)
	end
end

return table.freeze(ZorroComerFx)
