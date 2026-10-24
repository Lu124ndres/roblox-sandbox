--!strict
--[[
	Camara (tráiler)

	Dónde está la cámara en cada escena del video de la página del juego. Cada
	escena recibe los segundos desde que empezó, el HumanoidRootPart del
	jugador y el modelo del gigante (si está), y devuelve el CFrame y el campo
	de visión. Solo lo usa Director.client (tools/trailer); no es parte del juego.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local CENTER = WorldZones.craterCenter
local UP = Vector3.yAxis
local CRECE_SECONDS = 11.5 -- lo que dura "crece" en Director.server

local Camara = {}

local function flatTo(from: Vector3, to: Vector3): Vector3
	local d = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	return if d.Magnitude > 1e-3 then d.Unit else Vector3.zAxis
end

local function sideOf(dir: Vector3): Vector3
	return Vector3.new(-dir.Z, 0, dir.X)
end

-- Alto que sigue al del gigante sin saltos cuando evoluciona.
local smoothHeight = 20
local function giantHeight(giant: Model?, dt: number): number
	if giant then
		local target = giant:GetExtentsSize().Y
		smoothHeight += (target - smoothHeight) * math.min(1, dt * 2.2)
	end
	return smoothHeight
end

local function giantBase(giant: Model?): Vector3
	return if giant then giant:GetPivot().Position else CENTER
end

function Camara.reset(giant: Model?)
	smoothHeight = if giant then giant:GetExtentsSize().Y else 20
end

function Camara.para(
	escena: string,
	t: number,
	dt: number,
	root: BasePart,
	giant: Model?
): (CFrame?, number)
	local p, cf = root.Position, root.CFrame
	local look, right = cf.LookVector, cf.RightVector
	if escena == "pesca" then
		-- Detrás del hombro, con el mar adelante; se acerca despacio.
		local back = 12 - t * 0.5
		local from = p - look * back + right * 5 + UP * 4.5
		return CFrame.lookAt(from, p + look * 22 + UP * 1), 62
	elseif escena == "canasta" then
		-- Primer plano desde atrás a un costado: la canasta llenándose.
		local a = math.rad(200) + t * 0.18
		local offset = (look * math.cos(a) + right * math.sin(a)) * 9
		return CFrame.lookAt(p + offset + UP * 3.5, p + UP * 1.2), 45
	elseif escena == "puente" then
		-- Al costado del puente, siguiendo al jugador, con el arco adelante.
		local from = p - look * 9 + right * 15 + UP * 7
		return CFrame.lookAt(from, p + look * 22 + UP * 6), 64
	elseif escena == "alimenta" or escena == "amigos" then
		-- Detrás del jugador con teleobjetivo: el gigante grande al fondo.
		local h = giantHeight(giant, dt)
		local base = giantBase(giant)
		local toGiant = flatTo(p, base)
		local drift = if escena == "amigos" then 3 - t * 0.7 else 5 - t * 0.8
		local back = if escena == "amigos" then 19 else 16
		local from = p
			- toGiant * back
			+ sideOf(toGiant) * drift
			+ UP * (if escena == "amigos" then 12 else 8)
		return CFrame.lookAt(from, base + UP * h * 0.45), if escena == "amigos" then 44 else 32
	elseif escena == "entrena" then
		-- Bajo, sobre el estanque, desde un costado del jugador.
		local pond = WorldZones.pondCenter(1)
		local toPond = flatTo(p, pond)
		local from = p + sideOf(toPond) * (12 - t * 0.7) - toPond * 6 + UP * 7
		return CFrame.lookAt(from, pond + UP * 2), 62
	elseif escena == "mejoras" then
		local from = p - look * 9 + right * 3 + UP * 5
		return CFrame.lookAt(from, p + look * 12 + UP * 5), 62
	elseif escena == "crece" then
		-- De frente al gigante, desde abajo; se aleja y sube a medida que crece.
		local h = giantHeight(giant, dt)
		local gcf = if giant then giant:GetPivot() else CFrame.new(CENTER)
		local front = flatTo(Vector3.zero, gcf.LookVector)
		local a = math.rad(28) - t * 0.035
		local dir = front * math.cos(a) + sideOf(front) * math.sin(a)
		local dist = math.min(205, h * 1.55 + 28)
		local from = gcf.Position + dir * dist + UP * (h * 0.3 + 6)
		return CFrame.lookAt(from, gcf.Position + UP * h * 0.52), 58
	elseif escena == "titulo" then
		-- Sigue el mismo movimiento de "crece" (sin corte): el título sobre el gigante ya grande.
		return Camara.para("crece", t + CRECE_SECONDS, dt, root, giant)
	end
	return nil, 70
end

return Camara
