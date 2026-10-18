--!strict
--[[
	IceParts

	Colores y piezas del hábitat de hielo del zorro (IceLair), con primitivas
	(fase 1). Las piezas comunes (part, holder, light, emitter, at, ground) son
	las de LairParts; aquí van las que necesita el hielo:
		wedge(parent, size, cframe, color, options)   una cuña suelta
		triangle(parent, a, b, c, thick, color, o)    un triángulo cualquiera con
		                                              dos cuñas, de grosor `thick`
		slab(parent, center, edge, sides, thick, color, rng, o)
		                                              una losa plana e irregular:
		                                              polígono de `sides` lados con
		                                              la cara de arriba en center.Y
		outline(rng, size, bumps)                     un contorno con bultos que
		                                              nunca entra más que `size`
	Nada de Glass: el de Roblox refleja el cielo y se ve azul oscuro. El hielo es
	Ice o Glacier y la nieve, Snow. Todo anclado y local; chocan solo las piezas
	que se piden con collide = true (lo que se pisa).
]]

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

-- Losa plana con la cara de arriba en center.Y: un abanico de triángulos desde el
-- centro hasta los vértices del contorno (con algo de azar en el ángulo de cada uno).
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
	local mid = center - Vector3.new(0, thick / 2, 0)
	local spin = rng:NextNumber(0, TAU)
	local corners: { Vector3 } = {}
	for k = 1, sides do
		local a = spin + (k + rng:NextNumber(-0.22, 0.22)) / sides * TAU
		local reach = edge(a) * rng:NextNumber(1, 1.05)
		table.insert(corners, mid + Vector3.new(math.cos(a), 0, math.sin(a)) * reach)
	end
	for k = 1, sides do
		IceParts.triangle(parent, mid, corners[k], corners[k % sides + 1], thick, color, options)
	end
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

return table.freeze(IceParts)
