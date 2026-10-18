--!strict
--[[
	ZorroStand

	Une el zorro de agua (ReplicatedStorage.Shared.Zorro) con el cliente: el módulo
	lo gira, lo anima y hace sus trucos; aquí sus eventos se vuelven sonidos y
	efectos del juego (ZorroEventos: voces, ondas y temblor), ZorroAgua pone los
	cubitos de agua, la espuma de las puntas y el brillo de los ojos, y ZorroFx la
	bruma de las colas, las ondas de las pisadas y los fuegos.
	Las colas hacen todo su trabajo (detail) con la cámara cerca y sin modo rápido;
	lejos, Zorro/Colas hace menos con la misma silueta.
	Solo los modelos con huesos de zorro (Cola1_1 y HombroIzq).
	Misma forma que OrcaSwim para que GiantBody use uno u otro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Capas = require(ReplicatedStorage.Shared.Zorro.Comer.Capas)
local Zorro = require(ReplicatedStorage.Shared.Zorro)
local CraterMode = require(script.Parent.Parent.Ambient.CraterMode)
local Distance = require(script.Parent.Parent.Effects.Distance)
local ZorroAgua = require(script.Parent.Parent.Effects.ZorroAgua)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local OrcaSwim = require(script.Parent.OrcaSwim)
local ZorroComerFx = require(script.Parent.ZorroComerFx)
local ZorroEventos = require(script.Parent.ZorroEventos)
local ZorroEstela = require(script.Parent.Parent.Effects.ZorroEstela)
local ZorroFx = require(script.Parent.ZorroFx)

-- Detalle de las colas: más cerca que esto de la cámara (altos del zorro + studs); para
-- perderlo hay que alejarse un 15 % más (así no cambia a cada rato en el borde).
local DETAIL_HEIGHTS, DETAIL_STUDS, DETAIL_MARGIN = 2.5, 40, 1.15

local ZorroStand = {}

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
	local agua: ZorroAgua.Agua? = nil
	local fxFor: any = nil
	local estela = ZorroEstela.new()
	local detailed = true
	return {
		step = function(
			dt: number,
			height: number,
			lift: number,
			spin: number,
			anger: number,
			inner: Model?
		)
			local reach = (height * DETAIL_HEIGHTS + DETAIL_STUDS)
				* (if detailed then DETAIL_MARGIN else 1)
			detailed = Distance.fromCamera(motion.state.center) < reach
				and not ClientSettings.get("lowFx")
			local character = Players.LocalPlayer.Character
			local pivot = motion.step(dt, {
				height = height,
				lift = lift,
				spin = spin,
				anger = anger,
				inner = inner,
				detail = detailed,
				lookAt = if character then character:GetPivot().Position else nil,
				ice = CraterMode.get() == "ice",
			})
			local rig = motion.state.rig
			if rig ~= fxFor then
				if fx then
					ZorroFx.destroy(fx)
				end
				fxFor = rig
				fx = if rig then ZorroFx.attach(rig) else nil
				if agua then
					agua.destroy()
				end
				agua = if rig then ZorroAgua.attach(rig) else nil
			end
			if fx then
				ZorroFx.update(fx, motion, ClientSettings.fxScale(), lift > -height)
			end
			if agua then
				agua.step(dt, height, Capas.stageFor(height), lift > -height)
			end
			local events = motion.state.events
			if #events > 0 then
				motion.state.events = {}
				for _, event in events do
					ZorroEventos.play(motion, fx, agua, event)
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
			if agua then
				agua.destroy()
			end
			motion.destroy()
		end,
	}
end

return table.freeze(ZorroStand)
