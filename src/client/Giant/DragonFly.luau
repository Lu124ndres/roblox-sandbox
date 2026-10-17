--!strict
--[[
	DragonFly

	Une el dragón (ReplicatedStorage.Shared.Dragon) con el cliente: Dragon lo
	hace volar y anima sus huesos, Dragon.Fx dibuja el fuego y las estelas y
	avisa cada momento (rugido, aletazo, despegue, posarse, dormir...), y
	DragonCues lo vuelve sonido de su etapa (Audio/DragonVoces) y efectos del
	juego (polvo, humo, brasas, temblor de cámara más fuerte cuanto más cerca).
	Solo vuelan los modelos con alas (hueso AlaIzq1). Misma forma que OrcaSwim
	para que GiantBody use uno u otro.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dragon = require(ReplicatedStorage.Shared.Dragon)
local DragonFx = require(ReplicatedStorage.Shared.Dragon.Fx)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local DragonCues = require(script.Parent.DragonCues)
local OrcaSwim = require(script.Parent.OrcaSwim)

local DragonFly = {}

function DragonFly.attach(template: Model?, center: Vector3): OrcaSwim.Swim?
	if not template or not template:FindFirstChild("AlaIzq1", true) then
		return nil
	end
	local motion = Dragon.new(center)
	local cues = DragonCues.new(motion)
	local fx = DragonFx.new(motion, { cue = cues.cue, fxScale = ClientSettings.fxScale })
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
			fx.step(dt)
			cues.step(dt)
			return pivot
		end,
		top = motion.top,
		mouth = motion.mouth,
		water = motion.water,
		bite = motion.bite,
		fed = function(_) -- por ahora solo muerde (animación especial: pendiente)
			motion.bite()
		end,
		destroy = function()
			motion.destroy()
			fx.destroy()
			cues.destroy()
		end,
	}
end

return table.freeze(DragonFly)
