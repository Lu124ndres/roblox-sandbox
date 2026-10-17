--!strict
--[[
	Minotauro/Comer/Acentos

	Lo chico que se suma encima de las reacciones (Minotauro/Comer lleva el estado):
		- cada pez: traga con un cabeceo hacia atrás que se apaga enseguida, el
		  pecho se infla un poco y se le sacude una oreja (una vez cada una);
		- mirar: gira cabeza y cuello hacia el jugador local que le dio el pez
		  (lookAt) mientras le siga dando y un poco más (entra y sale suave);
		- guiño: ladea la cabeza hacia ese jugador, le para la oreja de ese lado,
		  baja la cabeza (anticipación) y le hace un cabezazo con la boca
		  entreabierta, como diciendo "gracias".
]]

local C = require(script.Parent.Parent.Trucos.Curvas)
local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local KICK = 10 -- 1/s: qué tan rápido se apaga el cabeceo de cada pez
local LOOK_IN, LOOK_OUT = 0.35, 0.5 -- s para empezar y dejar de mirarlo
local HEAD = 0.85 -- altura de la cabeza (fracción del alto) para apuntar la mirada

export type State = {
	fish: number,
	lastFish: number,
	lookAt: Vector3?,
	lookFrom: number,
	lookUntil: number,
	winkAt: number?,
	winkSide: number,
}

local Acentos = {}

function Acentos.new(): State
	return {
		fish = 0,
		lastFish = -math.huge,
		lookAt = nil,
		lookFrom = 0,
		lookUntil = 0,
		winkAt = nil,
		winkSide = 1,
	}
end

local function kick(s: State, now: number, pace: number): Pose.Pose
	local k = C.decay(now, s.lastFish, KICK / pace)
	local ear = if s.fish % 2 == 0 then "earL" else "earR"
	return { lookPitch = 0.06 * k, breathe = 0.025 * k, [ear] = 0.2 * k }
end

local function look(s: State, now: number, pivot: CFrame, height: number): Pose.Pose?
	local at = s.lookAt
	if not at then
		return nil
	elseif now > s.lookUntil then
		s.lookAt = nil
		return nil
	end
	local l = C.smooth(C.span(now, s.lookFrom, s.lookFrom + LOOK_IN))
		* (1 - C.smooth(C.span(now, s.lookUntil - LOOK_OUT, s.lookUntil)))
	local head = pivot.Position + Vector3.new(0, height * HEAD, 0)
	local v = pivot:VectorToObjectSpace(at - head)
	local yaw = math.atan2(-v.X, -v.Z) -- + a su izquierda
	local pitch = math.atan2(v.Y, Vector2.new(v.X, v.Z).Magnitude)
	return {
		lookYaw = math.clamp(yaw, -0.9, 0.9) * l,
		lookPitch = math.clamp(pitch, -0.3, 0.4) * 0.6 * l,
	}
end

-- Escrito hacia su izquierda; si el jugador está a su derecha se refleja.
local function wink(s: State, now: number, seconds: number): Pose.Pose?
	local at = s.winkAt
	if not at then
		return nil
	end
	local u = (now - at) / seconds
	if u >= 1 then
		s.winkAt = nil
		return nil
	end
	local w = C.hold(u, 0, 0.2, 0.75, 1)
	local dip = C.bell(C.span(u, 0.3, 0.45))
	local nod = C.decay(u, 0.45, 12) * (1 - C.smooth(C.span(u, 0.7, 1)))
	local p: Pose.Pose = {
		tilt = -0.28 * w,
		earL = 0.45 * C.bell(C.span(u, 0.05, 0.6)),
		earR = -0.15 * w,
		lookPitch = -0.1 * dip + 0.14 * nod,
		jaw = 0.25 * nod,
		tail1 = 0.4 * math.sin(u * 30) * w,
	}
	return if s.winkSide < 0 then Tipos.mirror(p) else p
end

-- Suma a `pose` el cabeceo del último pez, la mirada y el guiño.
function Acentos.add(
	s: State,
	pose: Pose.Pose,
	now: number,
	pace: number,
	pivot: CFrame,
	height: number,
	winkSeconds: number
)
	Pose.add(pose, kick(s, now, pace))
	local looking = look(s, now, pivot, height)
	if looking then
		Pose.add(pose, looking)
	end
	local winking = wink(s, now, winkSeconds)
	if winking then
		Pose.add(pose, winking)
	end
end

return table.freeze(Acentos)
