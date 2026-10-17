--!strict
--[[
	EvolveFx

	La animación de evolución de cualquier gigante, sincronizada para todos
	con la hora del servidor (inicio = EvolucionHasta - evolveSeconds):
		0 .. estallido   carga (EvolveCharge): aura, energía que converge,
		                 anillos que suben, brillo; retumbo que sube y
		                 temblor de cámara que crece.
		estallido        (EvolveLook.burstSeconds, 1.3 s) onBurst cambia el
		                 modelo escondido por el destello (EvolveBurst):
		                 columna de luz, onda, chispas, golpe y temblor fuerte.
		.. evolveSeconds calma: se apaga el brillo, caen chispas doradas, el
		                 polvo se disipa y el gigante crece al alto nuevo.
	Quien llega tarde (empezó hace más de 1.3 s) ve el estallido enseguida.
	El color sale de EvolveLook; el tamaño, del alto viejo y el nuevo.
	Respeta el modo rápido (sin partículas), los celulares (la mitad) y el
	temblor desactivado (CameraShake). Se limpia sola al terminar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local GiantStages = require(ReplicatedStorage.Shared.GiantStages)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local EvolveBurst = require(script.Parent.Parent.Effects.EvolveBurst)
local EvolveCharge = require(script.Parent.Parent.Effects.EvolveCharge)
local EvolveSound = require(script.Parent.Parent.Effects.EvolveSound)
local Device = require(script.Parent.Parent.Interface.Device)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local EvolveLook = require(script.Parent.EvolveLook)
local GiantBody = require(script.Parent.GiantBody)

export type Evolution = {
	finish: () -> (), -- termina ya: si no estalló, cambia el modelo igual
	cancel: () -> (), -- solo limpia (el cuerpo se va a destruir)
}

local AFTERGLOW_SECONDS = 2.6 -- lo que tardan en apagarse los efectos del estallido
local CHARGE_VOLUME, BURST_VOLUME = 0.55, 0.9
local CHARGE_SPEED = 1.3 -- la carga (3.4 s) acelerada para que su pico caiga en el estallido

local EvolveFx = {}

local function nearness(): number
	local character = Players.LocalPlayer.Character
	return if character then WorldZones.craterBlend(character:GetPivot().Position) else 0
end

-- startsAt: hora del servidor en que empezó la evolución. onBurst cambia el modelo.
function EvolveFx.play(
	body: GiantBody.Body,
	def: Config.GiantDef,
	stage: number,
	startsAt: number,
	onBurst: () -> ()
): Evolution
	local look = EvolveLook.forGiant(def)
	local burstAt = EvolveLook.burstSeconds()
	local endAt = math.max(Config.Giants.cycle.evolveSeconds, burstAt + AFTERGLOW_SECONDS)
	local calmSeconds = Config.Giants.cycle.evolveSeconds - burstAt
	local light = ClientSettings.get("lowFx")
	local rate = ClientSettings.fxScale() * (if Device.phone() then 0.5 else 1)
	local oldHeight, newHeight = body.height(), GiantStages.heightFor(stage)
	local strength = 0.6 + 0.2 * stage -- temblor: la última etapa sacude más

	local folder = Instance.new("Folder")
	folder.Name = "Evolucion"
	folder.Parent = Workspace
	local function elapsed(): number
		return Workspace:GetServerTimeNow() - startsAt
	end
	local charge = if elapsed() < burstAt
		then EvolveCharge.new(folder, look.accent, look.core, oldHeight, light, rate)
		else nil
	local hum = if charge
		then EvolveSound.play("EvolveCharge", CHARGE_VOLUME, CHARGE_SPEED, elapsed(), nearness())
		else nil
	local burst = false
	local done = false
	local nextShake = 0
	local connection: RBXScriptConnection? = nil

	local function cleanup()
		done = true
		if connection then
			connection:Disconnect()
		end
		if charge then
			charge.destroy()
		end
		if hum then
			hum:Destroy()
		end
		folder:Destroy()
	end

	local function explode(center: Vector3, ground: Vector3)
		burst = true
		onBurst()
		if charge then
			charge.release()
		end
		if hum then
			TweenService:Create(hum, TweenInfo.new(0.3), { Volume = 0 }):Play()
		end
		local near = nearness()
		EvolveSound.play("EvolveBurst", BURST_VOLUME, 1, 0, near)
		if near > 0 then
			CameraShake.shake((0.8 + 0.5 * stage) * near, 1.4)
		end
		EvolveBurst.play({
			folder = folder,
			center = center,
			ground = ground,
			oldHeight = oldHeight,
			newHeight = newHeight,
			accent = look.accent,
			core = look.core,
			gold = look.gold,
			dust = look.dust,
			water = look.ground == "water" and not body.flies,
			light = light,
			rate = rate,
			near = near,
		}, calmSeconds)
	end

	connection = RunService.RenderStepped:Connect(function()
		if not body.model.Parent then
			cleanup()
			return
		end
		local t = elapsed()
		local ground, top = body.water(), body.top()
		local center = ground:Lerp(top, 0.5)
		local inner = body.model:FindFirstChildOfClass("Model") -- el modelo de la etapa
		if charge then
			local p = math.clamp(t / burstAt, 0, 1)
			charge.update(center, ground, oldHeight, p, nearness(), inner)
		end
		if not burst then
			local near = nearness()
			if near > 0 and os.clock() >= nextShake then -- temblor que crece con la carga
				nextShake = os.clock() + 0.1
				local p = math.clamp(t / burstAt, 0, 1)
				CameraShake.shake((0.1 + 0.6 * p * p) * strength * near, 0.3)
			end
			if t >= burstAt then
				explode(center, ground)
			end
		elseif t >= endAt then
			cleanup()
		end
	end)

	return {
		finish = function()
			if not done and not burst then
				burst = true
				onBurst()
			end
			if not done then
				cleanup()
			end
		end,
		cancel = function()
			if not done then
				cleanup()
			end
		end,
	}
end

return table.freeze(EvolveFx)
