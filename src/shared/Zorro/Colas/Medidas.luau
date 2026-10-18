--!strict
--[[
	Zorro/Colas/Medidas

	Lo que se mide de cada cola al enlazar, en el espacio del pivote y en reposo
	(el modelo crece con ScaleTo, que escala todo igual: las cuentas siguen
	valiendo). Cada tramo gira con dos ángulos alrededor de ejes del CUERPO:
		fan   abre o cierra en el plano del abanico (eje adelante del cuerpo):
		      + lleva la punta hacia su derecha
		fold  pliega: + la punta va hacia atrás (y abajo), - hacia adelante; el
		      eje es perpendicular a la cola dentro del abanico
	Por cola:
		angle      ángulo de reposo en el abanico (0 arriba, + a su derecha); out,
		           el mismo dividido por el mayor (-1..1; el centro del abanico es 0)
		root/segs  dónde nace y el vector de cada tramo (el último se extrapola: no
		           hay hueso en la punta), para la cinemática de Limites
		turn*, up*, back*  cuánto dobla la cola (fan, fold por tramo) el giro del
		           cuerpo (por rad/s), un empuje hacia arriba y uno hacia atrás (por
		           alto/s): la inercia y el arrastre (empuje · (eje × dirección))
		seed, rate, delta, phases  su azar (Onda): ritmo propio (0.85..1.15),
		           desfase por tramo (0.3..0.5 rad) y las fases de sus senos; el
		           mismo en todos los clientes
	Cuerpo: una cápsula de la cadera al cuello (a, b, radius) donde no entra ninguna
	punta (el radio cubre las placas de los hombros), el piso (floor, el alto de las
	patas) del que no bajan y el alto del modelo (height: BodyInfo.bajada va en
	fracción de él).
]]

local Azar = require(script.Parent.Parent.Parent.Minotauro.Azar)
local Rig = require(script.Parent.Parent.Rig)

export type Tramo = { bone: Bone, fan: Vector3, fold: Vector3 }
export type Cola = {
	prefix: string,
	n: number,
	tramos: { Tramo },
	angle: number,
	out: number,
	solo: boolean, -- la única cola (la cría): al envolver o enroscar va entera a un costado
	root: Vector3,
	segs: { Vector3 },
	fanAxis: Vector3,
	foldAxis: Vector3,
	turnFan: number,
	turnFold: number,
	upFan: number,
	upFold: number,
	backFan: number,
	backFold: number,
	seed: number,
	rate: number,
	delta: number,
	phases: { number },
}
export type Medidas = {
	colas: { Cola },
	a: Vector3,
	b: Vector3,
	radius: number,
	floor: number,
	height: number, -- alto del modelo al enlazar (mismo espacio que el reposo)
	hip: number,
	unit: number, -- alto de la cadera sobre el piso: la unidad de los empujes
}

local RADIUS = 1.1 -- radio de la cápsula, en distancias entre hombros

local Medidas = {}

local function restPos(rig: Rig.Rig, name: string): Vector3?
	local rest = rig.rest[name]
	return if rest then rest.Position else nil
end

local function measureTail(rig: Rig.Rig, tail: Rig.Tail, center: Vector3, unit: number): Cola?
	local f = rig.frame
	local back = -f.forward
	local tramos: { Tramo } = {}
	local points: { Vector3 } = {}
	for j = 1, tail.segments do
		local name = `{tail.prefix}{j}`
		local bone, rest = rig.bones[name], rig.rest[name]
		if not (bone and rest) then
			return nil
		end
		table.insert(tramos, { bone = bone, fan = Vector3.zero, fold = Vector3.zero })
		table.insert(points, rest.Position)
	end
	local count = #points
	local last = points[count] - points[count - 1]
	table.insert(points, points[count] + last) -- la punta: un tramo más, como el anterior
	local segs: { Vector3 } = {}
	for j = 1, count do
		table.insert(segs, points[j + 1] - points[j])
	end
	local span = points[count + 1] - points[1]
	if span.Magnitude < 1e-4 then
		return nil
	end
	local d = span.Unit
	local angle = math.atan2(d:Dot(f.right), d:Dot(f.up))
	local inPlane = f.right * math.sin(angle) + f.up * math.cos(angle)
	local foldAxis = inPlane:Cross(back).Unit
	for _, tramo in tramos do -- los ejes, pasados al espacio de cada hueso
		local rest = rig.rest[tramo.bone.Name].Rotation
		tramo.fan = rest:VectorToObjectSpace(f.forward)
		tramo.fold = rest:VectorToObjectSpace(foldAxis)
	end
	-- Un empuje P dobla la cola con P · (eje × d) (+ = hacia donde gira el eje).
	local gFan, gFold = f.forward:Cross(d), foldAxis:Cross(d)
	-- Al girar el cuerpo (rad/s, + a su izquierda) cada punto va a up × r: la cola
	-- se queda atrás, la empuja al revés.
	local mid = (points[1] + points[count + 1]) / 2 - center
	local drag = -f.up:Cross(Vector3.new(mid.X, 0, mid.Z)) / unit
	local number = tonumber(string.match(tail.prefix, "(%d+)")) or 0
	local seed = number * 7919 + 17
	local phases = {}
	for k = 1, 8 do
		phases[k] = 2 * math.pi * Azar.unit(seed, 10 + k)
	end
	return {
		prefix = tail.prefix,
		n = count,
		tramos = tramos,
		angle = angle,
		out = 0,
		solo = false,
		root = points[1],
		segs = segs,
		fanAxis = f.forward,
		foldAxis = foldAxis,
		turnFan = drag:Dot(gFan),
		turnFold = drag:Dot(gFold),
		upFan = f.up:Dot(gFan),
		upFold = f.up:Dot(gFold),
		backFan = back:Dot(gFan),
		backFold = back:Dot(gFold),
		seed = seed,
		rate = 0.85 + 0.3 * Azar.unit(seed, 1),
		delta = 0.3 + 0.2 * Azar.unit(seed, 2),
		phases = phases,
	}
end

function Medidas.bind(rig: Rig.Rig): Medidas?
	local hip = restPos(rig, "Cadera") or restPos(rig, "Raiz")
	local neck = restPos(rig, "Cuello1") or restPos(rig, "Pecho")
	local left, right = restPos(rig, "HombroIzq"), restPos(rig, "HombroDer")
	if not (hip and neck and left and right) then
		return nil
	end
	local floor = math.huge
	for _, name in { "PieIzq", "PieDer", "ManoIzq", "ManoDer" } do
		local p = restPos(rig, name)
		if p then
			floor = math.min(floor, p.Y)
		end
	end
	floor = if floor == math.huge then 0 else floor
	local unit = math.max(hip.Y - floor, 1e-3)
	local center = Vector3.new(0, hip.Y, 0) -- gira sobre el pivote (base del modelo)
	local colas: { Cola } = {}
	local widest = 0
	for _, tail in rig.tails do
		local cola = measureTail(rig, tail, center, unit)
		if cola then
			widest = math.max(widest, math.abs(cola.angle))
			table.insert(colas, cola)
		end
	end
	for _, cola in colas do
		cola.out = if widest > 1e-3 then cola.angle / widest else 0
		cola.solo = #colas == 1
	end
	-- De izquierda a derecha por su ángulo en el abanico (el de Rig.tails mira solo el
	-- último hueso: con las colas en S dos vecinas del medio pueden salir al revés).
	table.sort(colas, function(x, y)
		return x.angle < y.angle
	end)
	return {
		colas = colas,
		a = hip,
		b = neck,
		radius = (left - right).Magnitude * RADIUS,
		floor = floor,
		height = rig.model:GetExtentsSize().Y,
		hip = hip.Y,
		unit = unit,
	}
end

return table.freeze(Medidas)
