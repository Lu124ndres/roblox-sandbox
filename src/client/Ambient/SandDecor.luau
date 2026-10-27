--!strict
--[[
	SandDecor

	Lo que asoma de la arena del desierto del cráter, con primitivas (fase 1):
	el costillar de una bestia enorme (arcos de hueso que salen de la arena),
	un fémur gigante semienterrado, huesitos sueltos y piedras. Todo anclado,
	sin colisión (no traba a nadie) y local, como la arena. Lo suelto queda
	dentro del primer anillo del laberinto (LOOSE_*), para no cruzar sus muros.
	show() lo hace subir desde la arena (como si el viento lo destapara) y
	hide() lo quita. Se arma una sola vez, la primera vez que se muestra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local SandShape = require(script.Parent.SandShape)

local CENTER = WorldZones.craterCenter
local BONE = Color3.fromRGB(232, 222, 196)
local STONE = Color3.fromRGB(150, 112, 82)
local RISE = 5 -- studs que suben al destaparse
local RISE_SECONDS = 1.2
-- Huesitos y piedras sueltas: entre el gigante (Config.Habitats.giantClearRadius) y el
-- anillo de muros de 130 del laberinto del hábitat completo (tools/blender/habitat_minotauro.py:
-- cara de adentro en 127,5 y nada más alto que una losa hasta 126). Más afuera cruzarían muros.
local LOOSE_MIN, LOOSE_MAX = 96, 120

local SandDecor = {}

local folder = Instance.new("Folder")
folder.Name = "DesiertoDetalles"
local parts: { BasePart } = {}
local rest: { CFrame } = {}
local generation = 0

local function piece(shape: Enum.PartType, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = if color == BONE then Enum.Material.SmoothPlastic else Enum.Material.Slate
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = folder
	table.insert(parts, part)
	table.insert(rest, cframe)
	return part
end

-- Un hueso (cilindro) de a a b.
local function bone(a: Vector3, b: Vector3, thick: number)
	local cframe = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	piece(Enum.PartType.Cylinder, Vector3.new((b - a).Magnitude, thick, thick), cframe, BONE)
end

-- Un punto en el cráter: ángulo (grados), radio y alto sobre la arena de ahí.
local function spot(angle: number, radius: number, above: number): Vector3
	local a = math.rad(angle)
	local x, z = CENTER.X + math.cos(a) * radius, CENTER.Z + math.sin(a) * radius
	return Vector3.new(x, SandShape.top(x, z) + above, z)
end

-- Costillar: columna medio enterrada y pares de costillas en arco, con hueco arriba.
local function ribcage(angle: number, radius: number)
	local middle = spot(angle, radius, -0.6)
	local a = math.rad(angle)
	local along = Vector3.new(-math.sin(a), 0, math.cos(a)) -- tangente al cráter
	local side = Vector3.new(math.cos(a), 0, math.sin(a))
	bone(middle - along * 15, middle + along * 15, 1.8)
	for i = 1, 6 do
		local s = (i - 3.5) * 4.4
		local size = 1 - math.abs(i - 3.5) / 5 -- más chicas hacia las puntas
		local width, height = 7 * size + 2, 11 * size + 3
		local root = middle + along * s
		for _, sign in { -1, 1 } do
			local last = root + side * sign * width
			for k = 1, 3 do
				local t = k / 3 * 0.42 * math.pi -- se corta antes de juntarse arriba
				local point = root
					+ side * sign * width * math.cos(t)
					+ Vector3.new(0, height * math.sin(t), 0)
				bone(last, point, 1.1)
				last = point
			end
		end
	end
end

local function build()
	ribcage(122, 132)
	-- Fémur: inclinado, una punta enterrada.
	local from, to = spot(236, 148, -1.5), spot(229, 150, 2.5)
	bone(from, to, 2.2)
	for _, tip in { from, to } do
		piece(Enum.PartType.Ball, Vector3.one * 3.6, CFrame.new(tip), BONE)
	end
	local rng = Random.new(7) -- siempre el mismo desierto
	for _ = 1, 6 do -- huesitos sueltos
		local angle, radius = rng:NextNumber(0, 360), rng:NextNumber(LOOSE_MIN, LOOSE_MAX)
		local length = rng:NextNumber(2.5, 5)
		local center = spot(angle, radius, 0.2)
		local dir = CFrame.Angles(0, rng:NextNumber(0, math.pi), 0).LookVector
		bone(center - dir * length / 2, center + dir * length / 2, rng:NextNumber(0.5, 0.8))
	end
	for _ = 1, 14 do -- piedras
		local size = rng:NextNumber(1.5, 4.5)
		local tilt = CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.3), 0)
		local at = spot(rng:NextNumber(0, 360), rng:NextNumber(LOOSE_MIN, LOOSE_MAX), size * 0.2)
		local shape = if rng:NextNumber() < 0.5 then Enum.PartType.Ball else Enum.PartType.Block
		piece(
			shape,
			Vector3.new(size, size * rng:NextNumber(0.5, 0.8), size * rng:NextNumber(0.8, 1.2)),
			CFrame.new(at) * tilt,
			STONE
		)
	end
end

-- Sube desde la arena. instant: ya en su lugar.
function SandDecor.show(instant: boolean)
	generation += 1
	local mine = generation
	if #parts == 0 then
		build()
	end
	folder.Parent = Workspace
	local frames = table.create(#parts) :: { CFrame }
	local elapsed = if instant then RISE_SECONDS else 0
	local connection: RBXScriptConnection
	local function step(dt: number)
		if mine ~= generation then
			connection:Disconnect()
			return
		end
		elapsed = math.min(elapsed + dt, RISE_SECONDS)
		local t = elapsed / RISE_SECONDS
		local down = RISE * (1 - t) ^ 2
		for i, cframe in rest do
			frames[i] = cframe - Vector3.new(0, down, 0)
		end
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		if t >= 1 then
			connection:Disconnect()
		end
	end
	connection = RunService.Heartbeat:Connect(step)
	step(0)
end

function SandDecor.hide()
	generation += 1
	folder.Parent = nil
end

return table.freeze(SandDecor)
