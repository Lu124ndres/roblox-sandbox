--!strict
--[[
	Zorro/Colas/Traduccion

	Pasa lo que ya piden los trucos y comer en la pose (Zorro/Pose, claves que se
	suman) al Intent de Colas, y arma el BodyInfo con lo que mueve al cuerpo:
		tailCalm  -> calma      (reposo 1; el aullido la baja, los fuegos la suben)
		tailLift  -> alto
		tailFan   -> abanico    (abanico, aullido, fuegos, festejos)
		tailWag   -> meneo      (comer, reverencia, sacudida); y un meneo grande
		             es que le gusta mucho: gusto sube con él
		enojo     -> alerta     (el enojo del servidor: colas altas y tensas)
	Claves nuevas que puede sumar cualquier capa a la pose, igual que las viejas:
		tailAlert (alerta), tailWrap (envolver), tailCurl (enroscar),
		tailSide (lado: el signo), tailGusto (gusto)
	El latigazo es una hora, no se suma: va en `extra` (se copia encima).
	El cuerpo: giro (rad/s), avance (cuánto se corre el centro, altos/s), subida
	(de pose.dy y crouch, altos/s) y sacudida (pose.shake).
]]

local Pose = require(script.Parent.Parent.Pose)
local Tipos = require(script.Parent.Tipos)

local MAX_RUN = 4 -- altos/s: más es un salto de lugar (cambio de modelo), no una carrera

export type Seguimiento = {
	intent: Tipos.Intent,
	body: Tipos.BodyInfo,
	center: Vector3?,
	dy: number?,
}

local Traduccion = {}

function Traduccion.new(): Seguimiento
	return { intent = {}, body = { giro = 0, avance = 0, subida = 0, sacudida = 0 } }
end

function Traduccion.intent(
	s: Seguimiento,
	pose: Pose.Pose,
	anger: number,
	extra: Tipos.Intent?
): Tipos.Intent
	local i = s.intent
	local wag = math.max(0, pose.tailWag or 0)
	i.calma = pose.tailCalm or 1
	i.alto = pose.tailLift or 0
	i.abanico = math.max(0, pose.tailFan or 0)
	i.meneo = wag
	i.gusto = math.clamp(math.max((wag - 0.6) / 0.8, pose.tailGusto or 0), 0, 1)
	i.alerta = math.clamp(0.8 * anger + (pose.tailAlert or 0), 0, 1)
	i.envolver = pose.tailWrap or 0
	i.enroscar = pose.tailCurl or 0
	i.lado = if (pose.tailSide or 1) < 0 then -1 else 1
	i.latigazo = nil
	if extra then
		local into: any = i
		for key, value in pairs(extra :: any) do
			into[key] = value
		end
	end
	return i
end

-- giro: rad/s del cuerpo; center: dónde está la base; height: alto del zorro (studs).
function Traduccion.body(
	s: Seguimiento,
	pose: Pose.Pose,
	giro: number,
	center: Vector3,
	height: number,
	dt: number
): Tipos.BodyInfo
	local b = s.body
	local dy = (pose.dy or 0) - (pose.crouch or 0) * 0.06 -- como lo baja Zorro/init
	local last, lastDy = s.center, s.dy
	local moved = if last then Vector3.new(center.X - last.X, 0, center.Z - last.Z) else nil
	local run = if moved then moved.Magnitude / dt / math.max(height, 1) else 0
	b.giro = giro
	b.avance = if run > MAX_RUN then 0 else run
	b.subida = if lastDy then (dy - lastDy) / dt else 0
	b.sacudida = pose.shake or 0
	s.center, s.dy = center, dy
	return b
end

return table.freeze(Traduccion)
