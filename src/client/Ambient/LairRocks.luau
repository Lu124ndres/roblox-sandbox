--!strict
--[[
	LairRocks

	Las rocas de obsidiana donde se posa el dragón, en los lugares del
	contrato Dragon/Guarida (perches): cada una tiene la cima plana y redonda
	justo a la altura de Guarida.point() con el radio `size` (ahí apoya las
	patas, y se puede pisar), un borde escalonado debajo y laderas de lajas
	de obsidiana, unas mates y otras brillosas, inclinadas hacia afuera, con
	vetas de magma que bajan hasta la lava. Al pie, costra agrietada sobre la
	lava y bloques sueltos medio hundidos; en las laderas, cristales de fuego.
	Nada sobresale de la cima: el nido (LairNest) es lo único que va encima.
	Las arma una vez LavaLair, que las sube y las hunde con la lava.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local LairCrystals = require(script.Parent.LairCrystals)
local LairParts = require(script.Parent.LairParts)

local P = LairParts
local LAVA = Guarida.lava
local BELOW = 14 -- studs que la roca sigue bajo la lava
local CAP = 4 -- grosor de la cima
local SLABS = 8
local LEAN = math.rad(11) -- las lajas se abren hacia abajo
local CRUST = Color3.fromRGB(84, 38, 28)

local LairRocks = {}

local rng = Random.new(17) -- siempre las mismas rocas

-- Veta de magma que baja zigzagueando por la cara de afuera de una laja.
local function vein(parent: Instance, slab: CFrame, width: number, height: number)
	local face = -2.1 -- la cara de afuera (la laja mira hacia -Z y tiene 4 de grosor)
	local last = slab * Vector3.new(rng:NextNumber(-0.2, 0.2) * width, height / 2 - 1.5, face)
	for k = 1, 3 do
		local y = height / 2 - 1.5 - height * k / 3
		local nextPoint = slab * Vector3.new(rng:NextNumber(-0.3, 0.3) * width, y, face)
		local thick = 1 - k * 0.15
		P.bar(parent, last, nextPoint, thick, 0.4, P.MAGMA, {
			material = Enum.Material.Neon,
			up = slab.LookVector,
		})
		last = nextPoint
	end
end

-- Las lajas alrededor del cuerpo, del pie (bajo la lava) a 1.5 bajo la cima.
local function slabs(parent: Instance, top: Vector3, radius: number, crystals: number)
	local bottom = LAVA - BELOW
	local height = top.Y - 1.5 - bottom
	local first = rng:NextNumber(0, math.pi * 2)
	for k = 1, SLABS do
		local a = first + k / SLABS * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local middle = Vector3.new(top.X, (bottom + top.Y - 1.5) / 2, top.Z) + out * (radius + 1.2)
		local slab = CFrame.lookAt(middle, middle + out) * CFrame.Angles(LEAN, 0, 0)
		local width = radius * rng:NextNumber(0.62, 0.9)
		local shiny = k % 3 == 0
		P.part(
			parent,
			Vector3.new(width, height, 4),
			slab,
			if shiny then P.OBSIDIAN else P.OBSIDIAN2,
			{
				material = if shiny then Enum.Material.Glass else Enum.Material.Basalt,
				reflectance = if shiny then 0.2 else 0,
				collide = true,
			}
		)
		if k % 3 == 1 then
			vein(parent, slab, width, height)
		elseif k == 2 or (crystals > 1 and k == 6) then
			-- A media ladera, sobre la lava: el eje del racimo sale hacia afuera y arriba.
			local y = LAVA + (top.Y - LAVA) * 0.45 - middle.Y
			local base = slab * CFrame.new(0, y, -2) * CFrame.Angles(math.rad(-55), 0, 0)
			LairCrystals.cluster(parent, base, rng:NextNumber(0.8, 1))
		end
	end
end

-- Bloques sueltos al pie, medio hundidos en la lava.
local function boulders(parent: Instance, top: Vector3, radius: number)
	for _ = 1, 3 do
		local a = rng:NextNumber(0, math.pi * 2)
		local size = rng:NextNumber(4, 7)
		local at = Vector3.new(top.X, LAVA, top.Z)
			+ Vector3.new(math.cos(a), 0, math.sin(a)) * (radius + 7)
		local tilt = CFrame.Angles(
			rng:NextNumber(-0.5, 0.5),
			rng:NextNumber(0, 6.3),
			rng:NextNumber(-0.5, 0.5)
		)
		P.part(
			parent,
			Vector3.new(size, size * 0.8, size * 1.1),
			CFrame.new(at) * tilt,
			P.OBSIDIAN,
			{
				material = Enum.Material.Glass,
				reflectance = 0.15,
			}
		)
	end
end

local function rock(parent: Instance, perch: Guarida.Perch)
	local top = Guarida.point(perch)
	local radius = perch.size
	local bottom = LAVA - BELOW
	local body = top.Y - CAP - 3 - bottom
	local foot = Vector3.new(top.X, bottom, top.Z)
	-- La cima: su cara de arriba queda justo en top.Y.
	P.column(parent, top - Vector3.new(0, CAP, 0), CAP, radius, P.OBSIDIAN2, { collide = true })
	P.column(
		parent,
		top - Vector3.new(0, CAP + 3, 0),
		3.2,
		radius + 1.8,
		P.OBSIDIAN,
		{ collide = true }
	)
	-- El cuerpo: más ancho abajo.
	P.column(parent, foot, body * 0.55, radius + 5, P.OBSIDIAN, { collide = true })
	P.column(
		parent,
		foot + Vector3.new(0, body * 0.5, 0),
		body * 0.5,
		radius + 3,
		P.OBSIDIAN2,
		{ collide = true }
	)
	slabs(parent, top, radius, if radius > 30 then 2 else 1)
	-- Costra agrietada alrededor, sobre la lava.
	P.column(parent, Vector3.new(top.X, LAVA - 0.6, top.Z), 1.2, radius + 9, CRUST, {
		material = Enum.Material.CrackedLava,
	})
	boulders(parent, top, radius)
end

function LairRocks.build(parent: Instance)
	for _, perch in Guarida.perches do
		rock(parent, perch)
	end
end

return table.freeze(LairRocks)
