--!strict
--[[
	GuidePath

	El camino de la guía: con PathfindingService calcula por dónde se llega de
	verdad al destino (al volcán se va por el puente, no en línea recta) y pone
	delante del jugador una fila de flechas flotando a la altura del pecho
	(GuideArrow), que apuntan por el camino.

	Las flechas están clavadas en el mundo: cada una ocupa una marca fija del
	camino (cada SPACING studs) y mira hacia donde sigue el camino ahí. Cuando
	el jugador camina no giran ni se corren: la que deja atrás se va y aparece
	otra al final. El camino solo se recalcula si cambia el destino o si el
	jugador se aleja mucho de él. Todo solo en este cliente.
]]

local PathfindingService = game:GetService("PathfindingService")

local GuideArrow = require(script.Parent.GuideArrow)

local RECOMPUTE_SECONDS = 1.5 -- como mucho, un cálculo cada tanto
local OFF_PATH = 16 -- studs fuera del camino que fuerzan otro cálculo
local LOOK_AHEAD = 9 -- la flecha del jugador apunta a este punto del camino
local COUNT = 5 -- flechas a la vista
local SPACING = 8 -- studs de camino entre flecha y flecha
local FIRST = 7 -- la primera, al menos así de adelante del jugador
local HEIGHT = 3.2 -- sobre el suelo del camino (el pecho de un jugador)
local SCALE = 0.85
local TURN_SPAN = 3 -- studs a cada lado para medir la dirección (suaviza las curvas)

export type Path = {
	update: (position: Vector3, target: Vector3, t: number) -> Vector3,
	hide: () -> (),
}

local GuidePath = {}

type Route = { points: { Vector3 }, lengths: { number }, total: number }

local function route(points: { Vector3 }): Route
	local lengths, total = { 0 }, 0
	for k = 2, #points do
		total += (points[k] - points[k - 1]).Magnitude
		lengths[k] = total
	end
	return { points = points, lengths = lengths, total = total }
end

-- El punto del camino a `s` studs del comienzo.
local function at(path: Route, s: number): Vector3
	local points, lengths = path.points, path.lengths
	s = math.clamp(s, 0, path.total)
	for k = 2, #points do
		if lengths[k] >= s then
			local span = lengths[k] - lengths[k - 1]
			local t = if span > 1e-3 then (s - lengths[k - 1]) / span else 0
			return points[k - 1]:Lerp(points[k], t)
		end
	end
	return points[#points]
end

-- A qué distancia del comienzo del camino está el jugador, y qué tan lejos de él.
local function progress(path: Route, position: Vector3): (number, number)
	local points = path.points
	local bestS, bestDistance = 0, math.huge
	for k = 1, #points - 1 do
		local a, b = points[k], points[k + 1]
		local ab = b - a
		local t = if ab.Magnitude > 1e-3
			then math.clamp((position - a):Dot(ab) / ab:Dot(ab), 0, 1)
			else 0
		local distance = (a + ab * t - position).Magnitude
		if distance < bestDistance then
			bestS, bestDistance = path.lengths[k] + ab.Magnitude * t, distance
		end
	end
	return bestS, bestDistance
end

function GuidePath.new(): Path
	local arrows: { GuideArrow.Shape } = {}
	for k = 1, COUNT do
		arrows[k] = GuideArrow.shape(GuideArrow.group(), `Camino{k}`, SCALE)
	end
	local finder =
		PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, WaypointSpacing = 4 })
	local current: Route? = nil
	local goal: Vector3? = nil
	local computing, lastCompute = false, -math.huge

	local function compute(from: Vector3, to: Vector3)
		computing, lastCompute, goal = true, os.clock(), to
		task.spawn(function()
			local ok = pcall(function()
				finder:ComputeAsync(from, to)
			end)
			local found = {}
			if ok and finder.Status == Enum.PathStatus.Success then
				for _, waypoint in finder:GetWaypoints() do
					table.insert(found, waypoint.Position)
				end
			end
			current = route(if #found >= 2 then found else { from, to }) -- sin camino: en línea recta
			computing = false
		end)
	end

	local function hide()
		for _, arrow in arrows do
			for _, item in arrow do
				item.part.Transparency = 1
			end
		end
	end

	local function update(position: Vector3, target: Vector3, t: number): Vector3
		local feet = position - Vector3.new(0, 3, 0)
		local stale = current == nil or goal == nil or (goal :: Vector3 - target).Magnitude > 4
		local s, away = 0, 0
		if not stale then
			s, away = progress(current :: Route, feet)
		end
		if
			(stale or away > OFF_PATH)
			and not computing
			and os.clock() - lastCompute > RECOMPUTE_SECONDS
		then
			compute(feet, target)
		end
		local path = current
		if stale or not path then
			hide()
			return target
		end
		-- Marcas fijas del camino: la primera que queda al menos FIRST studs adelante.
		local first = math.floor((s + FIRST) / SPACING) + 1
		for k, arrow in arrows do
			local mark = (first + k - 1) * SPACING
			if mark > path.total - 4 then
				for _, item in arrow do
					item.part.Transparency = 1
				end
				continue
			end
			local spot = at(path, mark)
			local ahead = at(path, mark + TURN_SPAN) - at(path, mark - TURN_SPAN)
			local flat = Vector3.new(ahead.X, 0, ahead.Z)
			if flat.Magnitude < 1e-3 then
				continue
			end
			local bob = math.sin(t * 2.4 + mark * 0.35) * 0.3
			local floating = spot + Vector3.new(0, HEIGHT + bob, 0)
			-- La última se asoma un poco transparente: el camino sigue.
			local fade = if k == COUNT then 0.45 else 0
			GuideArrow.pose(arrow, CFrame.lookAt(floating, floating + flat.Unit), fade)
		end
		return at(path, s + LOOK_AHEAD) + Vector3.new(0, 3, 0)
	end

	return { update = update, hide = hide }
end

return GuidePath
