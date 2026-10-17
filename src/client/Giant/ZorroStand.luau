--!strict
--[[
	ZorroStand

	Une el zorro de agua (ReplicatedStorage.Shared.Zorro) con el cliente: el módulo
	lo gira, lo anima y hace sus trucos; aquí sus eventos se vuelven sonidos y
	efectos del juego (respetan volumen, alcance y modo rápido) y ZorroFx pone la
	luz de la gema, la bruma de las colas, las ondas de las pisadas y los fuegos:
		howl    aullido: un llamado largo y agudo, ondas en el agua y temblor
		fan     abanico de colas: destellos cian en las puntas y un soplo
		crouch  se agacha para saltar: el agua se agita
		land    cae del salto: gran salpicón, ondas y temblor
		shake   se sacude: gotas por todo el cuerpo
		happy   reverencia de juego: corazones
		orbs    fuegos fatuos: orbes de agua que suben a su alrededor
	Los de su animación al comer (fed: cada pez, los raros y los combos) los
	pone ZorroComerFx, y ZorroEstela la estela de agua cuando corre.
	Solo los modelos con huesos de zorro (Cola1_1 y HombroIzq).
	Misma forma que OrcaSwim para que GiantBody use uno u otro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zorro = require(ReplicatedStorage.Shared.Zorro)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local OrcaSwim = require(script.Parent.OrcaSwim)
local ZorroComerFx = require(script.Parent.ZorroComerFx)
local ZorroEstela = require(script.Parent.Parent.Effects.ZorroEstela)
local ZorroFx = require(script.Parent.ZorroFx)

local SHAKE_REACH = 260
local CYAN = Color3.fromRGB(110, 255, 240)

local ZorroStand = {}

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

local function play(motion: Zorro.Motion, fx: ZorroFx.ZorroFx?, event: Zorro.Event)
	local kind = event.kind
	local height = motion.state.height
	local water = motion.water()
	local size = math.max(1, height / 12)
	if kind == "howl" then
		Sounds.play("OrcaCall", motion.top(), 1.45)
		Sounds.play("Roar", motion.top(), 1.6)
		for k = 1, 3 do
			task.delay(k * 0.35, Fx.ring, water, height * (0.5 + k * 0.3), 1.6)
		end
		shake(motion.top(), 0.35, 1.6)
	elseif kind == "fan" then
		Sounds.play("Whoosh", motion.top(), 0.7)
		local rig = motion.state.rig
		for _, tail in (if rig then rig.tails else {}) do
			local tip = motion.point(`{tail.prefix}4`)
			if tip then
				Fx.sparkle(tip, CYAN, 8)
			end
		end
	elseif kind == "crouch" then
		Fx.ring(water, height * 0.4, 0.8)
	elseif kind == "land" then
		Sounds.play("BigSplash", water)
		Fx.splash(water, 2.2 * size)
		Fx.ring(water, height * 0.9, 1.5)
		shake(water, 0.5, 0.6)
	elseif kind == "shake" then
		Sounds.play("Whoosh", motion.top(), 1.3)
		for _, bone in { "Pecho", "Cadera", "Cabeza" } do
			local at = motion.point(bone)
			if at then
				Fx.splash(at, 0.9 * size)
			end
		end
	elseif kind == "happy" then
		Fx.hearts(motion.top(), 5)
	elseif kind == "orbs" and fx then
		Sounds.play("CoinPop", motion.top(), 0.6)
		ZorroFx.orbs(fx, motion, math.max(1, math.round(6 * ClientSettings.fxScale())))
		Fx.sparkle(motion.top(), CYAN, 20)
	elseif kind ~= "orbs" then
		ZorroComerFx.play(motion, event)
	end
end

function ZorroStand.attach(template: Model?, center: Vector3): OrcaSwim.Swim?
	if
		not template
		or not template:FindFirstChild("Cola1_1", true)
		or not template:FindFirstChild("HombroIzq", true)
	then
		return nil
	end
	local motion = Zorro.new(center)
	local fx: ZorroFx.ZorroFx? = nil
	local fxFor: any = nil
	local estela = ZorroEstela.new()
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
			local rig = motion.state.rig
			if rig ~= fxFor then
				if fx then
					ZorroFx.destroy(fx)
				end
				fxFor = rig
				fx = if rig then ZorroFx.attach(rig) else nil
			end
			if fx then
				ZorroFx.update(fx, motion, ClientSettings.fxScale(), lift > -height)
			end
			local events = motion.state.events
			if #events > 0 then
				motion.state.events = {}
				for _, event in events do
					play(motion, fx, event)
				end
			end
			ZorroComerFx.step(motion)
			ZorroEstela.update(estela, motion.state.trail, height, motion.water().Y, motion.point)
			return pivot
		end,
		top = motion.top,
		mouth = motion.mouth,
		water = motion.water,
		bite = motion.bite,
		fed = function(info: OrcaSwim.FedInfo)
			motion.fed({
				from = info.from,
				rarity = info.rarity,
				isLocal = info.isLocal,
				streak = info.streak,
			})
		end,
		destroy = function()
			ZorroEstela.destroy(estela)
			if fx then
				ZorroFx.destroy(fx)
			end
			motion.destroy()
		end,
	}
end

return table.freeze(ZorroStand)
