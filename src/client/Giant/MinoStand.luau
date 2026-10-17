--!strict
--[[
	MinoStand

	Une el minotauro (ReplicatedStorage.Shared.Minotauro) con el cliente: el
	módulo lo gira, lo anima y hace sus trucos; aquí sus eventos se vuelven
	sonidos (Audio/MinoVoces, por etapa y suelo) y efectos del juego (respetan
	volumen, alcance y modo rápido). Sobre arena (def.sand: su desierto) los
	golpes levantan polvo (Effects/SandFx); sobre agua salpican (Fx):
		stomp    pisotón: polvo o salpicadura, anillo y temblor (más fuerte cerca)
		roar     rugido (agudo en el becerro, grave y con capas en la forma final)
		land     cae de un salto: como el pisotón, más fuerte
		step     pisada al caminar: polvito o salpicadura chica y un anillo
		sit      se sienta: golpe y el polvo se abre por el suelo
		standup  se levanta: resoplido de esfuerzo
		snort, yawn, sniff  resoplido, bostezo y olfateo (solo sonido)
		evolve   resoplido corto (la evolución la dibuja otro módulo)
		flex     destellos dorados alrededor
		happy    corazones sobre la cabeza
	Sus reacciones a cada pez (fed: Minotauro/Comer) suenan con Audio/MinoVocesComer
	y se ven con MinoComer (ojos que brillan, oro, papelitos, corazones, eructo).
	Un evento desconocido no hace nada. En reposo gruñe o respira cada tanto.
	Solo los modelos con huesos de minotauro (OrejaIzq y BrazoIzq, sin alas).
	Misma forma que OrcaSwim para que GiantBody use uno u otro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Minotauro = require(ReplicatedStorage.Shared.Minotauro)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local MinoVoces = require(script.Parent.Parent.Audio.MinoVoces)
local MinoVocesComer = require(script.Parent.Parent.Audio.MinoVocesComer)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local SandFx = require(script.Parent.Parent.Effects.SandFx)
local MinoComer = require(script.Parent.MinoComer)
local MinoSuelo = require(script.Parent.MinoSuelo)
local OrcaSwim = require(script.Parent.OrcaSwim)

local SHAKE_REACH = 240
local GRUNT_EVERY = NumberRange.new(9, 16) -- segundos de calma entre gruñidos en reposo

local MinoStand = {}

MinoVoces.add(MinoVocesComer)

local rng = Random.new()

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

-- Pisotón y caída de un salto: tamaño de la salpicadura, radio del anillo
-- (en altos del gigante) y temblor. Sobre arena el polvo usa SAND_SCALE de eso.
local SLAMS: { [string]: { splash: number, ring: number, shake: number } } = {
	stomp = { splash = 1.5, ring = 0.6, shake = 0.5 },
	land = { splash = 2, ring = 0.8, shake = 0.4 },
}
local SAND_SCALE = 0.75

-- Lo que se ve en el suelo con cada golpe (arena o agua).
local function impact(kind: string, ground: Vector3, height: number, force: number, sand: boolean)
	local size = math.max(1, height / 12) * force
	local slam = SLAMS[kind]
	if slam then
		local radius = height * slam.ring * force
		if sand then
			SandFx.slam(ground, SAND_SCALE * slam.splash * size, radius)
		else
			Fx.splash(ground, slam.splash * size)
			Fx.ring(ground, radius, 1.2)
		end
		shake(ground, slam.shake * force, 0.6)
	elseif kind == "step" then
		if sand then
			SandFx.puff(ground, 0.6 * size)
		else
			Fx.splash(ground, 0.6 * size)
			Fx.ring(ground, height * 0.18, 0.9)
		end
	elseif kind == "sit" then
		if sand then
			SandFx.settle(ground, size)
		else
			Fx.splash(ground, size)
		end
		shake(ground, 0.25 * force, 0.4)
	end
end

local function play(motion: Minotauro.Motion, kind: string, place: MinoSuelo.Place)
	local profile = motion.state.profile
	local ground = MinoSuelo.ground(motion, place)
	MinoVoces.play(kind, {
		stage = place.stage,
		voice = profile.voice,
		head = motion.top(),
		ground = ground,
		sand = place.sand,
	})
	if kind == "roar" then
		shake(motion.top(), 0.35 / profile.voice, 1.4)
	elseif kind == "flex" then
		Fx.sparkle(motion.top(), UIConfig.Colors.Coins, 24)
	elseif kind == "happy" then
		Fx.hearts(motion.top(), 5)
	elseif not MinoComer.play(motion, kind, ground, place.sand, shake) then
		impact(kind, ground, motion.state.height, profile.stomp, place.sand)
	end
end

function MinoStand.attach(template: Model?, center: Vector3): OrcaSwim.Swim?
	if
		not template
		or not template:FindFirstChild("OrejaIzq", true)
		or not template:FindFirstChild("BrazoIzq", true)
		or template:FindFirstChild("AlaIzq1", true)
	then
		return nil
	end
	local motion = Minotauro.new(center)
	local place = MinoSuelo.place(nil)
	local placeFor: Model? = nil
	local calm, nextGrunt = 0, rng:NextNumber(GRUNT_EVERY.Min, GRUNT_EVERY.Max)
	return {
		step = function(
			dt: number,
			height: number,
			lift: number,
			spin: number,
			anger: number,
			inner: Model?
		)
			local pivot = motion.step(
				dt,
				{ height = height, lift = lift, spin = spin, anger = anger, inner = inner }
			)
			local holder = if inner then inner.Parent or inner else nil
			if inner ~= placeFor or place.model ~= holder then
				placeFor = inner
				place = MinoSuelo.place(inner)
			end
			local events = motion.state.events
			calm += dt
			if #events > 0 then
				motion.state.events = {}
				calm = 0
				for _, event in events do
					play(motion, event.kind, place)
				end
			elseif calm > nextGrunt then
				calm, nextGrunt = 0, rng:NextNumber(GRUNT_EVERY.Min, GRUNT_EVERY.Max)
				play(motion, "grunt", place)
			end
			return pivot
		end,
		top = motion.top,
		mouth = motion.mouth,
		water = motion.water,
		bite = motion.bite,
		fed = motion.fed,
		destroy = motion.destroy,
	}
end

return table.freeze(MinoStand)
