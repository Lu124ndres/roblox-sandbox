--!strict
--[[
	ZorroAgua

	El agua y el hielo pegados al zorro de agua v2 (todo del cliente):
		cubitos   bloques de agua que flotan alrededor del cuerpo y las colas
		          (ZorroCubos)
		puntas    espuma que salpica de las puntas de las colas cuando se mueven
		          rápido y, desde el adulto, destellos de hielo (ZorroPuntas)
		ojos      una PointLight tenue en el hueso de la cabeza: el brillo de los
		          ojos y de la marca de la frente
	Y las ráfagas de cada evento (burst, con ZorroRafagas): shake (gotas por
	todo el cuerpo), land, splash y pounce (golpe en el agua por GroundFx y
	corona de espuma), step (espuma chica), fan (espuma y hielo en las puntas,
	los cubitos se abren) y howl (los cubitos suben, hielo en las puntas).

	Modo rápido (fxScale = 0): ni cubitos, ni espuma, ni destellos, ni luz.
	Lejos de la cámara (Effects/Distance) o con el zorro escondido, lo mismo.
		attach(rig) -> Agua
		agua.step(dt, alto, etapa, visible)
		agua.burst(evento, punto?)   punto: dónde pegó (el agua bajo el zorro o la pata)
		agua.destroy()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rig = require(ReplicatedStorage.Shared.Zorro.Rig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Distance = require(script.Parent.Distance)
local GroundFx = require(script.Parent.GroundFx)
local ZorroCubos = require(script.Parent.ZorroCubos)
local ZorroPuntas = require(script.Parent.ZorroPuntas)
local ZorroRafagas = require(script.Parent.ZorroRafagas)

local REACH, MIN_REACH = 6, 220 -- se ve hasta REACH altos del zorro desde la cámara
local SHAKE_BONES = { "Cabeza", "Pecho", "Columna", "Cadera" }
local EYE = Color3.fromRGB(207, 246, 255) -- ojo y marca (brillo)

export type Agua = {
	step: (dt: number, height: number, stage: number, visible: boolean) -> (),
	burst: (kind: string, at: Vector3?) -> (),
	destroy: () -> (),
}

local ZorroAgua = {}

local function at(bone: Bone?): Vector3?
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

local function eyeLight(head: Bone?): PointLight?
	if not head then
		return nil
	end
	local light = Instance.new("PointLight")
	light.Name = "BrilloOjos"
	light.Color = EYE
	light.Shadows = false
	light.Enabled = false
	light.Parent = head
	return light
end

function ZorroAgua.attach(rig: Rig.Rig): Agua
	local cubos = ZorroCubos.new(rig)
	local puntas = ZorroPuntas.new(rig)
	local light = eyeLight(rig.bones.Cabeza)
	local height, stage, shown = 10, 1, false

	local function step(dt: number, h: number, st: number, visible: boolean)
		height, stage = h, math.clamp(st, 1, 4)
		local head = at(rig.bones.Cabeza) or at(rig.bones.Raiz)
		local reach = math.max(MIN_REACH, h * REACH) * Distance.scale()
		shown = visible
			and ClientSettings.fxScale() > 0
			and head ~= nil
			and Distance.fromCamera(head) <= reach
		ZorroCubos.update(cubos, dt, h, stage, shown)
		ZorroPuntas.update(puntas, dt, h, stage, shown)
		if light then
			if light.Enabled ~= shown then
				light.Enabled = shown
			end
			if shown then
				light.Range = math.clamp(h * 0.25, 4, 40)
				light.Brightness = 0.7 + 0.15 * math.sin(os.clock() * 1.7)
			end
		end
	end

	local function burst(kind: string, point: Vector3?)
		if not shown then
			return
		end
		local h, big = height, stage >= 3
		local ground = point or at(rig.bones.Raiz) or Vector3.zero
		if kind == "shake" then
			for _, name in SHAKE_BONES do
				local p = at(rig.bones[name])
				if p then
					ZorroRafagas.drops(p, h, 12)
				end
			end
			for _, p in ZorroPuntas.positions(puntas) do
				ZorroRafagas.drops(p, h, 6)
				if big then
					ZorroRafagas.glints(p, h, 3)
				end
			end
		elseif kind == "land" or kind == "splash" or kind == "pounce" then
			local strong = kind == "land"
			GroundFx.splash(ground, (if strong then 2 else 1) * math.max(1, h / 12))
			ZorroRafagas.crown(ground, h, (if strong then 14 else 6) + 3 * stage)
			if big and strong then
				ZorroRafagas.glints(ground, h, 10)
			end
		elseif kind == "step" then
			ZorroRafagas.foam(ground, h, 4)
		elseif kind == "fan" or kind == "howl" then
			ZorroCubos.lift(cubos, if kind == "fan" then 1 else 0.7)
			for _, p in ZorroPuntas.positions(puntas) do
				if kind == "fan" then
					ZorroRafagas.foam(p, h, 8)
				end
				if big then
					ZorroRafagas.glints(p, h, 5)
				end
			end
		end
	end

	local function destroy()
		ZorroCubos.destroy(cubos)
		ZorroPuntas.destroy(puntas)
		if light then
			light:Destroy()
		end
	end

	return { step = step, burst = burst, destroy = destroy }
end

return table.freeze(ZorroAgua)
