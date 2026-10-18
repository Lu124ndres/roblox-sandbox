--!strict
--[[
	GuidePath

	El camino de la guía: con PathfindingService calcula por dónde se llega de
	verdad al destino (al volcán se va por el puente, no en línea recta) y lo
	recalcula si el jugador se sale de él o cambia el destino. Devuelve el punto
	del camino unos pasos adelante del jugador (hacia ahí apunta GuideArrow) y
	dibuja en el piso una fila corta de chevrones verdes que corren hacia
	adelante. Todo solo en este cliente: no queda nada puesto en el mapa.
]]

local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local GREEN = Color3.fromRGB(80, 235, 90)
local RECOMPUTE_SECONDS = 1.5 -- como mucho, un cálculo cada tanto
local OFF_PATH = 10 -- studs fuera del camino que fuerzan otro cálculo
local LOOK_AHEAD = 9 -- la flecha apunta a este punto del camino
local CHEVRONS = 6
local SPACING = 4
local FIRST = 3 -- studs delante del jugador donde empieza la fila
local SCROLL = 4 -- studs por segundo que corren los chevrones
local LIFT = 1.4 -- sobre el suelo: el pasto alto del terreno taparía los chevrones
-- Cada chevrón ">" apunta hacia adelante: dos brazos que salen de la punta hacia atrás.
local TIP = Vector3.new(0, 0, -0.7)
local WING = Vector3.new(0.9, 0, 0.5) -- el extremo de un brazo (x se espeja)
local ARM = (WING - TIP).Magnitude + 0.2

export type Path = {
	update: (position: Vector3, target: Vector3, t: number) -> Vector3,
	hide: () -> (),
}

local GuidePath = {}

local function chevron(index: number, folder: Folder): { Part }
	local arms = {}
	for side = -1, 1, 2 do
		local arm = Instance.new("Part")
		arm.Name = `Chevron{index}_{side}`
		arm.Size = Vector3.new(0.4, 0.1, ARM)
		arm.Color = GREEN
		arm.Material = Enum.Material.Neon
		arm.Anchored = true
		arm.CanCollide, arm.CanQuery, arm.CanTouch = false, false, false
		arm.CastShadow = false
		arm.Transparency = 1
		arm:SetAttribute("Lado", side)
		arm.Parent = folder
		table.insert(arms, arm)
	end
	return arms
end

-- Punto y dirección del camino a `distance` studs desde el punto `from` del tramo `index`.
local function along(
	points: { Vector3 },
	index: number,
	from: Vector3,
	distance: number
): (Vector3, Vector3)
	local position = from
	for k = index, #points - 1 do
		local nextPoint = points[k + 1]
		local segment = nextPoint - position
		local length = segment.Magnitude
		if length >= distance and length > 1e-3 then
			return position + segment.Unit * distance, segment.Unit
		end
		distance -= length
		position = nextPoint
	end
	local last = points[#points]
	local before = points[math.max(#points - 1, 1)]
	local direction = if (last - before).Magnitude > 1e-3
		then (last - before).Unit
		else Vector3.zAxis
	return last, direction
end

-- El tramo más cercano al jugador, el punto de ese tramo y a qué distancia está.
local function closest(points: { Vector3 }, position: Vector3): (number, Vector3, number)
	local bestIndex, bestPoint, bestDistance = 1, points[1], math.huge
	for k = 1, #points - 1 do
		local a, b = points[k], points[k + 1]
		local ab = b - a
		local t = if ab.Magnitude > 1e-3
			then math.clamp((position - a):Dot(ab) / ab:Dot(ab), 0, 1)
			else 0
		local point = a + ab * t
		local distance = (point - position).Magnitude
		if distance < bestDistance then
			bestIndex, bestPoint, bestDistance = k, point, distance
		end
	end
	return bestIndex, bestPoint, bestDistance
end

function GuidePath.new(): Path
	local folder = Instance.new("Folder")
	folder.Name = "CaminoGuia"
	folder.Parent = Workspace
	local marks: { { Part } } = {}
	for k = 1, CHEVRONS do
		marks[k] = chevron(k, folder)
	end
	local path =
		PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, WaypointSpacing = 4 })
	local points: { Vector3 } = {}
	local goal: Vector3? = nil
	local computing, lastCompute = false, -math.huge

	local function compute(from: Vector3, to: Vector3)
		computing, lastCompute, goal = true, os.clock(), to
		task.spawn(function()
			local ok = pcall(function()
				path:ComputeAsync(from, to)
			end)
			local found = {}
			if ok and path.Status == Enum.PathStatus.Success then
				for _, waypoint in path:GetWaypoints() do
					table.insert(found, waypoint.Position)
				end
			end
			points = if #found >= 2 then found else { from, to } -- sin camino: en línea recta
			computing = false
		end)
	end

	local function hide()
		for _, arms in marks do
			for _, arm in arms do
				arm.Transparency = 1
			end
		end
	end

	local function update(position: Vector3, target: Vector3, t: number): Vector3
		local feet = position - Vector3.new(0, 3, 0)
		local stale = goal == nil or (goal :: Vector3 - target).Magnitude > 4 or #points < 2
		local index, onPath, away = 1, feet, 0
		if not stale then
			index, onPath, away = closest(points, feet)
		end
		if
			(stale or away > OFF_PATH)
			and not computing
			and os.clock() - lastCompute > RECOMPUTE_SECONDS
		then
			compute(feet, target)
		end
		if #points < 2 then
			hide()
			return target
		end
		local scroll = (t * SCROLL) % SPACING
		for k, arms in marks do
			local spot, direction = along(points, index, onPath, FIRST + scroll + (k - 1) * SPACING)
			local frame = CFrame.lookAt(spot, spot + Vector3.new(direction.X, 0, direction.Z))
				+ Vector3.new(0, LIFT, 0)
			local fade = 0.15 + 0.85 * ((k - 1 + scroll / SPACING) / CHEVRONS)
			for _, arm in arms do
				local side = arm:GetAttribute("Lado") :: number
				local wing = Vector3.new(WING.X * side, 0, WING.Z)
				arm.CFrame = frame * CFrame.lookAt((TIP + wing) / 2, TIP)
				arm.Transparency = math.clamp(fade, 0, 1)
			end
		end
		local ahead = along(points, index, onPath, LOOK_AHEAD)
		return ahead
	end

	return { update = update, hide = hide }
end

return GuidePath
