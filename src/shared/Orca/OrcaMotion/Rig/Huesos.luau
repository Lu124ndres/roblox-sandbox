--!strict
--[[
	OrcaMotion/Rig/Huesos

	Escribir un hueso de la orca:
		raw    gira el hueso en los ejes del modelo medidos en Rig.bind, tal
		       cual (pitch + = el frente sube; yaw + = el frente va a la izquierda).
		       Es la cuenta de siempre; la usa el modelo viejo.
		set    lo mismo con la convención del contrato (la punta del hueso; en
		       Cola y AletaCola es la de atrás), limitado contra Limites. Es lo
		       que usa el v2: nunca escribe un ángulo fuera de tope.
	Las dos escriben Bone.Transform solo si algo cambió más que WRITE_EPSILON.
	`soft` acerca un valor a su tope con una curva suave (sin chocar de golpe).
]]

local Limites = require(script.Parent.Parent.Limites)
local Tipos = require(script.Parent.Tipos)

type Rig = Tipos.Rig

local WRITE_EPSILON = 0.002 -- rad (~0.1°): menos que esto no se ve
local KNEE = 0.75 -- fracción del tope desde la que la curva empieza a frenar

local Huesos = {}

-- Un eje sin rango no se mueve (el hueso no gira así en el modelo).
local function lo(range: Limites.Rango?): number
	return if range then range.min else 0
end

local function hi(range: Limites.Rango?): number
	return if range then range.max else 0
end

-- Lleva x hacia el rango sin pasarse: igual hasta KNEE del tope, después se
-- acerca al tope con una tangente hiperbólica (llega con velocidad cero).
function Huesos.soft(x: number, range: Limites.Rango?): number
	if not range then
		return x
	end
	local limit = if x >= 0 then range.max else range.min
	local size = math.abs(limit)
	local over = math.abs(x) - KNEE * size
	if over <= 0 then
		return x
	end
	local room = (1 - KNEE) * size
	local mag = KNEE * size + room * math.tanh(over / math.max(room, 1e-6))
	return if x >= 0 then mag else -mag
end

function Huesos.raw(rig: Rig, name: string, pitch: number, yaw: number, roll: number)
	local bone, axes = rig.bones[name], rig.axes[name]
	if not bone or not axes then
		return
	end
	local value = Vector3.new(pitch, yaw, roll)
	local last = rig.written[name]
	if last and (last - value).Magnitude < WRITE_EPSILON then
		return
	end
	rig.written[name] = value
	local transform = CFrame.fromAxisAngle(axes.pitch, pitch)
	if yaw ~= 0 then
		transform *= CFrame.fromAxisAngle(axes.yaw, yaw)
	end
	if roll ~= 0 then
		transform *= CFrame.fromAxisAngle(axes.roll, roll)
	end
	bone.Transform = transform
end

-- Limita un ángulo (convención del contrato) contra Limites; sin entrada, igual.
function Huesos.limit(
	name: string,
	pitch: number,
	yaw: number,
	roll: number
): (number, number, number)
	local limits = Limites.porHueso[name]
	if not limits then
		return pitch, yaw, roll
	end
	return math.clamp(Huesos.soft(pitch, limits.pitch), lo(limits.pitch), hi(limits.pitch)),
		math.clamp(Huesos.soft(yaw, limits.yaw), lo(limits.yaw), hi(limits.yaw)),
		math.clamp(Huesos.soft(roll, limits.roll), lo(limits.roll), hi(limits.roll))
end

-- Con la convención del contrato y limitado. Devuelve lo que escribió.
function Huesos.set(
	rig: Rig,
	name: string,
	pitch: number,
	yaw: number,
	roll: number
): (number, number, number)
	pitch, yaw, roll = Huesos.limit(name, pitch, yaw, roll)
	local sign = if rig.back[name] then -1 else 1
	Huesos.raw(rig, name, sign * pitch, sign * yaw, (rig.rollSign[name] or 1) * roll)
	return pitch, yaw, roll
end

return table.freeze(Huesos)
