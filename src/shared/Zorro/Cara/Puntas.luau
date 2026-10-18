--!strict
--[[
	Zorro/Cara/Puntas

	La punta de cada oreja con inercia: sigue a su oreja (que ya mueve
	Zorro/Pose) con un resorte, así llega tarde cuando la oreja, la cabeza o el
	cuerpo giran, se pasa un poco y se acomoda. Se mide cuánto giró la oreja en el
	mundo desde el cuadro anterior, en los ejes del cuerpo que lleva la oreja
	(cabeceo: adelante y atrás; alabeo: de lado), y el resorte persigue ese giro
	más el doblez pedido (base): la punta queda en (resorte - giro de la oreja).
		new()                         la memoria de una punta
		step(m, rig, s, base, etapa, dt)  (cabeceo, alabeo) de OrejaPunta{s}
		reset(m)                      olvida el cuadro anterior (al volver el detalle)
	Topes: lo medido limpio en tools/blender/zorro_v2_poses.py (punta atrás 1.0,
	adelante 0.5, las cuatro etapas), con margen.
]]

local Resorte = require(script.Parent.Parent.Parent.Resorte)
local Rig = require(script.Parent.Parent.Rig)

export type Punta = {
	prev: CFrame?,
	pitch: number, -- giro acumulado de la oreja (rad, en el eje derecha del cuerpo)
	roll: number, -- giro acumulado de la oreja (rad, en el eje adelante del cuerpo)
	springPitch: Resorte.Resorte,
	springRoll: Resorte.Resorte,
}

local PITCH_MIN, PITCH_MAX = -0.5, 0.9 -- rad: adelante (-) y atrás (+)
local ROLL_MAX = 0.35 -- rad de lado
local JUMP = 0.6 -- rad en un cuadro: es un salto del modelo (aparece, evoluciona), no un giro
-- Resorte por etapa: la cría rebota más; la forma final, orejas grandes y pesadas.
local HZ = { 2.6, 2.3, 2.0, 1.6 }
local DAMPING = { 0.3, 0.35, 0.42, 0.5 }

local Puntas = {}

function Puntas.new(): Punta
	return {
		prev = nil,
		pitch = 0,
		roll = 0,
		springPitch = Resorte.new(),
		springRoll = Resorte.new(),
	}
end

function Puntas.reset(m: Punta)
	m.prev = nil
	m.springPitch.x, m.springPitch.v = m.pitch, 0
	m.springRoll.x, m.springRoll.v = m.roll, 0
end

function Puntas.step(
	m: Punta,
	rig: Rig.Rig,
	s: string,
	base: number,
	etapa: number,
	dt: number
): (number, number)
	local ear, axes = rig.bones[`Oreja{s}`], rig.axes[`Oreja{s}`]
	if not ear or not axes then
		return math.clamp(base, PITCH_MIN, PITCH_MAX), 0
	end
	local now = ear.TransformedWorldCFrame.Rotation
	local prev = m.prev
	if prev then
		local axis, angle = (now * prev:Inverse()):ToAxisAngle()
		if angle == angle and math.abs(angle) < JUMP then -- angle == angle: no es NaN
			m.pitch += axis:Dot(now:VectorToWorldSpace(axes.pitch)) * angle
			m.roll += axis:Dot(now:VectorToWorldSpace(axes.roll)) * angle
		end
	end
	m.prev = now
	-- Mantiene los números chicos: corre el origen del acumulado y del resorte juntos.
	if math.abs(m.pitch) > 50 or math.abs(m.roll) > 50 then
		m.springPitch.x -= m.pitch
		m.springRoll.x -= m.roll
		m.pitch, m.roll = 0, 0
	end
	local e = math.clamp(etapa, 1, #HZ)
	local pitch = Resorte.step(m.springPitch, m.pitch + base, dt, HZ[e], DAMPING[e]) - m.pitch
	local roll = Resorte.step(m.springRoll, m.roll, dt, HZ[e], DAMPING[e]) - m.roll
	return math.clamp(pitch, PITCH_MIN, PITCH_MAX), math.clamp(roll, -ROLL_MAX, ROLL_MAX)
end

return table.freeze(Puntas)
