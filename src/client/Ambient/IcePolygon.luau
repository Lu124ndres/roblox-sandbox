--!strict
--[[
	IcePolygon

	Medidas de un contorno de hielo (IceShards): un polígono de Vector2 alrededor
	del centro (el origen), en orden antihorario. Geometría pura, sin piezas.
		gap(p, q)            distancia del centro al lado p-q
		inner(corners)       lo más cerca del centro que pasa el borde
		reach(corners)       lo más lejos que llega un vértice
		edgeAt(corners, a)   a qué distancia está el borde en la dirección a
		triangles(corners)   el polígono partido en n - 2 triángulos (IceParts.fan)
		room(walls)          hasta dónde se puede llegar en cada dirección sin
		                     pasar ninguna pared (dir unitaria, a `at` del centro)
		around(angle)        la dirección `angle` del plano en el mundo (X, 0, Z)
]]

local IcePolygon = {}

-- Distancia del centro (el origen) al segmento p-q.
function IcePolygon.gap(p: Vector2, q: Vector2): number
	local d = q - p
	local t = math.clamp(-p:Dot(d) / d:Dot(d), 0, 1)
	return (p + d * t).Magnitude
end

function IcePolygon.inner(corners: { Vector2 }): number
	local best = math.huge
	for k, p in corners do
		best = math.min(best, IcePolygon.gap(p, corners[k % #corners + 1]))
	end
	return best
end

function IcePolygon.reach(corners: { Vector2 }): number
	local best = 0
	for _, p in corners do
		best = math.max(best, p.Magnitude)
	end
	return best
end

local function cross(a: Vector2, b: Vector2): number
	return a.X * b.Y - a.Y * b.X
end

function IcePolygon.edgeAt(corners: { Vector2 }, angle: number): number
	local dir = Vector2.new(math.cos(angle), math.sin(angle))
	for k, p in corners do
		local q = corners[k % #corners + 1]
		local side = q - p
		local den = cross(dir, side)
		if math.abs(den) > 1e-9 then
			local r, s = cross(p, side) / den, cross(p, dir) / den
			if r > 0 and s >= 0 and s <= 1 then
				return r
			end
		end
	end
	return IcePolygon.reach(corners)
end

-- p dentro del triángulo a-b-c (en sentido antihorario), sin contar el borde.
local function within(p: Vector2, a: Vector2, b: Vector2, c: Vector2): boolean
	return cross(b - a, p - a) > 0 and cross(c - b, p - b) > 0 and cross(a - c, p - c) > 0
end

-- Triángulos que cubren el polígono (antihorario), cortando orejas: n - 2 en vez de
-- los n de un abanico desde el centro. Si no encuentra oreja, cierra con el abanico.
function IcePolygon.triangles(corners: { Vector2 }): { { Vector2 } }
	local left, list: { { Vector2 } } = table.clone(corners), {}
	while #left > 3 do
		local n, cut = #left, false
		for i = 1, n do
			local a, b, c = left[(i - 2) % n + 1], left[i], left[i % n + 1]
			local ear = cross(b - a, c - b) > 1e-6
			for _, p in left do
				ear = ear and (p == a or p == b or p == c or not within(p, a, b, c))
			end
			if ear then
				table.insert(list, { a, b, c })
				table.remove(left, i)
				cut = true
				break
			end
		end
		if not cut then
			for k, p in left do
				table.insert(list, { Vector2.zero, p, left[k % #left + 1] })
			end
			return list
		end
	end
	table.insert(list, left)
	return list
end

function IcePolygon.around(angle: number): Vector3
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

export type Wall = { dir: Vector2, at: number }

function IcePolygon.room(walls: { Wall }): (angle: number) -> number
	return function(angle: number): number
		local v, best = Vector2.new(math.cos(angle), math.sin(angle)), math.huge
		for _, wall in walls do
			local toward = v:Dot(wall.dir)
			if toward > 0 then
				best = math.min(best, wall.at / toward)
			end
		end
		return best
	end
end

return table.freeze(IcePolygon)
