--!strict
--[[
	IceParts

	Colores y piezas del hábitat de hielo del zorro (IceLair), con primitivas
	(fase 1). Las piezas comunes (part, holder, light, emitter, at, ground) son
	las de LairParts; aquí van las que necesita el hielo:
		wedge(parent, size, cframe, color, options)   una cuña suelta
		triangle(parent, a, b, c, thick, color, o)    un triángulo cualquiera con
		                                              dos cuñas, de grosor `thick`
		fan(parent, center, corners, thick, color, o) una losa plana sobre un
		                                              polígono (IceShards.shape) con
		                                              la cara de arriba en center.Y
		slab(parent, center, edge, sides, thick, color, rng, o)
		                                              una losa de `sides` lados sobre
		                                              un contorno (outline)
		chunk(parent, rng, at, out, size, color)      un trozo roto y torcido
		outline(rng, size, bumps)                     un contorno con bultos que
		                                              nunca entra más que `size`
	Nada de Glass: el de Roblox refleja el cielo y se ve azul oscuro. El hielo es
	Ice o Glacier y la nieve, Snow. Todo anclado y local; chocan solo las piezas
	que se piden con collide = true (lo que se pisa).
]]

local IcePolygon = require(script.Parent.IcePolygon)
local LairParts = require(script.Parent.LairParts)

local rgb = Color3.fromRGB
local TAU = math.pi * 2

local IceParts = {}

-- Paleta (biblia del zorro: hielo #BFF3FF, espuma #E6F7FF, brillo #CFF6FF).
IceParts.ICE = rgb(222, 243, 252) -- cara de arriba de los témpanos
IceParts.ICE_EDGE = rgb(176, 226, 244) -- bordes y trozos rotos
IceParts.ICE_DEEP = rgb(96, 186, 222) -- lo que queda bajo el agua y las grietas
IceParts.SNOW = rgb(240, 248, 255)
IceParts.FROST = rgb(212, 234, 247) -- escarcha sobre la roca
IceParts.CRYSTAL = rgb(191, 243, 255)
IceParts.CRYSTAL_DEEP = rgb(143, 216, 240)
IceParts.CRYSTAL_LIGHT = rgb(230, 247, 255)
IceParts.GLOW = rgb(207, 246, 255)
IceParts.ROCKS = { rgb(84, 94, 108), rgb(100, 110, 124), rgb(70, 78, 92), rgb(116, 124, 138) }

export type Options = {
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?,
}

function IceParts.wedge(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: Options?
): WedgePart
	local o: Options = options or {}
	local wedge = Instance.new("WedgePart")
	wedge.Size, wedge.CFrame, wedge.Color = size, cframe, color
	wedge.Material = o.material or Enum.Material.Ice
	wedge.Transparency = o.transparency or 0
	wedge.Anchored = true
	wedge.CanCollide = o.collide == true
	wedge.CanQuery, wedge.CanTouch = false, false
	wedge.TopSurface, wedge.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	wedge.Parent = parent
	return wedge
end

-- Un triángulo a-b-c con dos cuñas rectas (el grosor va a lo largo de la normal,
-- centrado en el plano del triángulo).
function IceParts.triangle(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	thick: number,
	color: Color3,
	options: Options?
)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	-- `a` queda frente al lado más largo (bc): la altura desde `a` lo parte en dos rectos.
	if abd > acd and abd > bcd then
		a, c = c, a
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	IceParts.wedge(
		parent,
		Vector3.new(thick, height, math.abs(ab:Dot(back))),
		CFrame.fromMatrix((a + b) / 2, right, up, back),
		color,
		options
	)
	IceParts.wedge(
		parent,
		Vector3.new(thick, height, math.abs(ac:Dot(back))),
		CFrame.fromMatrix((a + c) / 2, -right, up, -back),
		color,
		options
	)
end

export type Edge = (angle: number) -> number

-- Contorno de una losa: a qué distancia del centro está el borde en cada dirección.
-- Con bultos y entrantes, pero siempre más afuera que `size` (la parte que se pisa).
function IceParts.outline(rng: Random, size: number, bumps: number): Edge
	local p1, p2, p3 = rng:NextNumber(0, TAU), rng:NextNumber(0, TAU), rng:NextNumber(0, TAU)
	return function(angle: number): number
		local wave = 0.5 + 0.25 * math.sin(2 * angle + p1) + 0.15 * math.sin(3 * angle + p2)
		return size * (1.15 + bumps * (wave + 0.1 * math.sin(5 * angle + p3)))
	end
end

-- Losa plana con la cara de arriba en center.Y sobre el polígono `corners` (Vector2
-- desde el centro, en orden antihorario), en los triángulos de IcePolygon.triangles.
function IceParts.fan(
	parent: Instance,
	center: Vector3,
	corners: { Vector2 },
	thick: number,
	color: Color3,
	options: Options?
)
	local mid = center - Vector3.new(0, thick / 2, 0)
	local function at(p: Vector2): Vector3
		return mid + Vector3.new(p.X, 0, p.Y)
	end
	for _, t in IcePolygon.triangles(corners) do
		IceParts.triangle(parent, at(t[1]), at(t[2]), at(t[3]), thick, color, options)
	end
end

-- Losa de `sides` lados sobre un contorno (con algo de azar en el ángulo de cada vértice).
function IceParts.slab(
	parent: Instance,
	center: Vector3,
	edge: Edge,
	sides: number,
	thick: number,
	color: Color3,
	rng: Random,
	options: Options?
)
	local spin = rng:NextNumber(0, TAU)
	local corners: { Vector2 } = {}
	for k = 1, sides do
		local a = spin + (k + rng:NextNumber(-0.22, 0.22)) / sides * TAU
		local reach = edge(a) * rng:NextNumber(1, 1.05)
		table.insert(corners, Vector2.new(math.cos(a), math.sin(a)) * reach)
	end
	IceParts.fan(parent, center, corners, thick, color, options)
end

-- Pieza de bloque con las opciones del hielo (material Ice si no se dice otro).
function IceParts.block(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: Options?
): Part
	local o: Options = options or {}
	return LairParts.part(parent, size, cframe, color, {
		material = o.material or Enum.Material.Ice,
		collide = o.collide,
		transparency = o.transparency,
	})
end

-- Un trozo de hielo caído, torcido al azar, con el frente hacia `out`.
function IceParts.chunk(
	parent: Instance,
	rng: Random,
	at: Vector3,
	out: Vector3,
	size: Vector3,
	color: Color3
): Part
	local tilt = CFrame.Angles(rng:NextNumber(0.15, 0.5), rng:NextNumber(-0.4, 0.4), 0)
	local frame = CFrame.lookAt(at, at + out)
		* tilt
		* CFrame.Angles(0, 0, rng:NextNumber(-0.3, 0.3))
	return IceParts.block(parent, size, frame, color)
end

return table.freeze(IceParts)
