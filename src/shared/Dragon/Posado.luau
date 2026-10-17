--!strict
--[[
	Dragon/Posado

	Lo que el dragón posado tiene que respetar de la roca, con los huesos reales
	(Rig.posed: la pose de este cuadro) y la orientación del cuerpo (rot: solo
	giro, en el mundo):
		clearance(rig, rot)  cuánto tiene que estar la raíz sobre la cima para que
		                     el punto más bajo (garras de las patas, o la panza si
		                     está echado) apoye justo en ella
		level(rig, rot)      cuánto cabecear (rad) para que las patas de adelante
		                     y las de atrás apoyen a la misma altura
		balance(b, rig, rot) lo corrige de a poco (b.level); si no alcanza con
		                     LEVEL, dobla los brazos (b.bend, Dragon/Patas)
		tail(rig, pivot, surface)  levanta los huesos de la cola que se meterían
		                     en la roca (cada uno lo justo, de la base a la punta):
		                     sobre la cima queda apoyada y fuera de ella cuelga
		surface(perch, point)  alto de la roca bajo un punto: plana en la cima y
		                     cayendo empinada desde el borde
	Las garras y la panza son los puntos de apoyo de Rig.contacts.
]]

local Guarida = require(script.Parent.Guarida)
local Rig = require(script.Parent.Rig)

local LEVEL = { -0.2, 0.5 } -- cuánto puede cabecear para nivelar (rad)
local SLOPE = 2.2 -- cuánto baja la roca por cada stud fuera de la cima
local TAIL_GAP = 0.55 -- la cola tiene grosor y aletas: en largos de pierna
local FRONT = { "ManoIzq", "ManoDer" }
local BACK = { "PieIzq", "PieDer" }

local Posado = {}

local function lowest(rig: Rig.Rig, rot: CFrame, frame: CFrame, names: { string }): number?
	local low: number? = nil
	for _, name in names do
		local p = Rig.contact(rig, name)
		if p then
			local y = rot:VectorToWorldSpace(frame:PointToObjectSpace(p)).Y
			low = if low then math.min(low, y) else y
		end
	end
	return low
end

function Posado.clearance(rig: Rig.Rig, rot: CFrame): number
	local frame = Rig.frame(rig)
	local low =
		lowest(rig, rot, frame, { "ManoIzq", "ManoDer", "PieIzq", "PieDer", "Pecho", "Cadera" })
	return -(low or 0)
end

function Posado.level(rig: Rig.Rig, rot: CFrame): number
	local frame = Rig.frame(rig)
	local front, back = lowest(rig, rot, frame, FRONT), lowest(rig, rot, frame, BACK)
	local hand, foot = Rig.contact(rig, "ManoIzq"), Rig.contact(rig, "PieIzq")
	if not (front and back and hand and foot) then
		return 0
	end
	local span = math.max((hand - foot).Magnitude, 1e-3)
	return -math.asin(math.clamp((front - back) / span, -0.5, 0.5))
end

export type Balance = { level: number, bend: number }

function Posado.balance(b: Balance, rig: Rig.Rig, rot: CFrame)
	local err = Posado.level(rig, rot)
	if b.bend > 0 or (b.level >= LEVEL[2] and err > 0) then
		b.bend = math.clamp(b.bend + err * 1.2, 0, 1.2)
	else
		b.level = math.clamp(b.level + err * 0.5, LEVEL[1], LEVEL[2])
	end
end

function Posado.surface(perch: Guarida.Perch, point: Vector3): number
	local top = Guarida.point(perch)
	local out = Vector3.new(point.X - top.X, 0, point.Z - top.Z).Magnitude - perch.size
	return if out <= 0 then top.Y else math.max(top.Y - out * SLOPE, Guarida.lava)
end

-- pivot: el del modelo en el mundo este cuadro; surface: alto del suelo bajo un punto.
function Posado.tail(rig: Rig.Rig, pivot: CFrame, surface: (Vector3) -> number)
	local gap = TAIL_GAP * rig.shin * Rig.scale(rig)
	for i = 1, 6 do
		local name = `Cola{i}`
		local bone = rig.bones[name]
		if not bone then
			return
		end
		local world = pivot * Rig.posed(rig, name)
		local nextBone = rig.bones[`Cola{i + 1}`]
		local tip = if nextBone
			then pivot * Rig.posed(rig, nextBone.Name).Position
			else world * (bone.CFrame.Rotation:Inverse() * bone.CFrame.Position)
		local floor = surface(tip) + gap
		local segment = tip - world.Position
		local length = segment.Magnitude
		if tip.Y < floor and length > 1e-3 then
			local have = math.asin(math.clamp(segment.Y / length, -1, 1))
			local want = math.asin(math.clamp((floor - world.Position.Y) / length, -1, 1))
			local axis = segment:Cross(Vector3.yAxis)
			if axis.Magnitude > 1e-4 then
				local localAxis = world:VectorToObjectSpace(axis.Unit)
				bone.Transform *= CFrame.fromAxisAngle(localAxis, want - have)
				table.clear(rig.cache)
			end
		end
	end
end

return table.freeze(Posado)
