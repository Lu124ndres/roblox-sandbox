--!strict
--[[
	Zorro/Rutina/Trazo

	Una línea quebrada (plana) con las esquinas redondeadas por arcos de círculo:
	así el rumbo gira parejo (radio `radius`: caminando a v studs/s gira a
	v / radius rad/s) y lo recorrido es el largo de verdad (los pasos no patinan).
	Si un tramo es corto, su arco se achica (como mucho FILLET de cada tramo).
		build(points, radius)  arma los pedazos: rectas y arcos
		sample(trazo, s)       posición y dirección a s studs del inicio
]]

export type Pedazo = {
	from: Vector3,
	dir: Vector3, -- dirección al empezar
	length: number,
	center: Vector3?, -- arco: su centro
	sign: number, -- arco: +1 gira a un lado, -1 al otro
	radius: number,
}
export type Trazo = { pieces: { Pedazo }, length: number }

local FILLET = 0.45 -- parte de cada tramo que puede comerse un arco

local Trazo = {}

local function rotate(v: Vector3, a: number): Vector3
	local c, s = math.cos(a), math.sin(a)
	return Vector3.new(v.X * c - v.Z * s, 0, v.X * s + v.Z * c)
end

local function cross(a: Vector3, b: Vector3): number
	return a.X * b.Z - a.Z * b.X
end

function Trazo.build(points: { Vector3 }, radius: number): Trazo
	local n = #points
	local dirs, lens, cut, radii = {}, {}, {}, {}
	for i = 1, n - 1 do
		local d = points[i + 1] - points[i]
		lens[i] = d.Magnitude
		dirs[i] = if lens[i] > 1e-6 then d.Unit else Vector3.new(0, 0, -1)
	end
	cut[1], cut[n] = 0, 0
	for i = 2, n - 1 do
		local angle = math.acos(math.clamp(dirs[i - 1]:Dot(dirs[i]), -1, 1))
		local half = math.tan(math.min(angle, 3.1) / 2)
		local w = math.min(radius * half, FILLET * lens[i - 1], FILLET * lens[i])
		cut[i] = if angle > 1e-3 then w else 0
		radii[i] = if angle > 1e-3 then w / half else 0
	end
	local pieces: { Pedazo } = {}
	local total = 0
	for i = 1, n - 1 do
		local from = points[i] + dirs[i] * cut[i]
		local length = lens[i] - cut[i] - cut[i + 1]
		table.insert(pieces, { from = from, dir = dirs[i], length = length, sign = 0, radius = 0 })
		total += length
		local w = cut[i + 1]
		if w > 0 then
			local start = points[i + 1] - dirs[i] * w
			local sign = if cross(dirs[i], dirs[i + 1]) >= 0 then 1 else -1
			local angle = math.acos(math.clamp(dirs[i]:Dot(dirs[i + 1]), -1, 1))
			local r = radii[i + 1]
			table.insert(pieces, {
				from = start,
				dir = dirs[i],
				length = r * angle,
				center = start + rotate(dirs[i], sign * math.pi / 2) * r,
				sign = sign,
				radius = r,
			})
			total += r * angle
		end
	end
	if #pieces == 0 then
		local p = points[1] or Vector3.zero
		table.insert(
			pieces,
			{ from = p, dir = Vector3.new(0, 0, -1), length = 0, sign = 0, radius = 0 }
		)
	end
	return { pieces = pieces, length = total }
end

function Trazo.sample(t: Trazo, s: number): (Vector3, Vector3)
	local pieces = t.pieces
	s = math.clamp(s, 0, t.length)
	for k, piece in pieces do
		if s <= piece.length or k == #pieces then
			local u = math.clamp(s, 0, piece.length)
			local center = piece.center
			if center then
				local a = piece.sign * u / piece.radius
				return center + rotate(piece.from - center, a), rotate(piece.dir, a)
			end
			return piece.from + piece.dir * u, piece.dir
		end
		s -= piece.length
	end
	return pieces[1].from, pieces[1].dir
end

return table.freeze(Trazo)
