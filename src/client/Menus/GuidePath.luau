--!strict
--[[
	GuidePath

	El camino de la guía: con PathfindingService calcula por dónde se llega de
	verdad al destino (al volcán se va por el puente, no en línea recta), lo
	redondea (sin esquinas) y por él avanza una fila de flechas flotando a la
	altura del pecho (GuideArrow), como en los simuladores.

	Las flechas se deslizan sin parar hacia adelante por el camino, como una
	cinta: aparecen suave delante del jugador, avanzan y se desvanecen al final
	de la fila. La cinta sale del jugador y se une al camino unos pasos más
	adelante, así lo sigue en cada cuadro mientras camina. El camino se
	recalcula si cambia el destino o si el jugador se aleja de él. Todo solo en este
	cliente: no hay nada puesto en el mapa.
]]

local PathfindingService = game:GetService("PathfindingService")

local GuideArrow = require(script.Parent.GuideArrow)

local RECOMPUTE_SECONDS = 0.6 -- como mucho, un cálculo cada tanto
local OFF_PATH = 10 -- studs fuera del camino que fuerzan otro cálculo
local JOIN = 10 -- la cinta sale del jugador y se une al camino así de adelante
local COUNT = 6 -- flechas en la cinta
local SPACING = 7 -- studs de camino entre flecha y flecha
local FIRST = 5 -- la cinta empieza así de adelante del jugador
local FLOW = 9 -- studs por segundo que avanzan las flechas
local FADE = 0.3 -- fracción de la cinta en la que aparecen y se desvanecen
local HEIGHT = 3.2 -- sobre el suelo del camino (el pecho de un jugador)
local SCALE = 0.9
local TURN_SPAN = 4 -- studs a cada lado para medir la dirección
local ROUNDING = 3 -- pasadas de redondeo del camino (Chaikin)
local END_MARGIN = 6 -- antes del destino la cinta se acaba

export type Path = {
	update: (position: Vector3, target: Vector3, t: number) -> (),
	hide: () -> (),
}

local GuidePath = {}

type Route = { points: { Vector3 }, lengths: { number }, total: number }

-- Corta cada esquina en dos (Chaikin): tras unas pasadas el camino es una curva suave.
local function round(points: { Vector3 }): { Vector3 }
	for _ = 1, ROUNDING do
		if #points < 3 then
			break
		end
		local smooth = { points[1] }
		for k = 1, #points - 1 do
			local a, b = points[k], points[k + 1]
			table.insert(smooth, a:Lerp(b, 0.25))
			table.insert(smooth, a:Lerp(b, 0.75))
		end
		table.insert(smooth, points[#points])
		points = smooth
	end
	return points
end

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

-- La cinta que se ve: del jugador en línea recta hasta el punto del camino `join` studs
-- más adelante y de ahí por el camino. Se arma en cada cuadro, así sigue al jugador
-- mientras camina aunque el camino calculado todavía no se haya puesto al día.
local function fromPlayer(path: Route, feet: Vector3, join: number): Route
	local points = { feet, at(path, join) }
	for k, point in path.points do
		if path.lengths[k] > join then
			table.insert(points, point)
		end
	end
	return route(points)
end

-- 0 en el medio de la cinta, 1 en sus puntas: aparecen y se van de a poco.
local function fadeAt(along: number): number
	if along < FADE then
		return 1 - along / FADE
	elseif along > 1 - FADE then
		return (along - (1 - FADE)) / FADE
	end
	return 0
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
			-- Sin camino: en línea recta.
			current = route(round(if #found >= 2 then found else { from, to }))
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

	local function update(position: Vector3, target: Vector3, t: number)
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
		if stale or not current then
			hide()
			return
		end
		local path =
			fromPlayer(current :: Route, feet, math.min(s + JOIN, (current :: Route).total))
		-- La cinta va de `start` a `finish` por el camino; las flechas avanzan por ella y,
		-- al llegar al final, vuelven a aparecer al principio (ya invisibles por el fade).
		local start = FIRST
		local length = COUNT * SPACING
		local finish = math.min(start + length, path.total - END_MARGIN)
		local shift = (t * FLOW) % SPACING
		for k, arrow in arrows do
			local offset = ((k - 1) * SPACING + shift) % length
			local mark = start + offset
			if mark > finish then
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
			local floating = spot + Vector3.new(0, HEIGHT, 0)
			local fade = fadeAt(offset / math.max(finish - start, 1))
			GuideArrow.pose(arrow, CFrame.lookAt(floating, floating + flat.Unit), fade)
		end
	end

	return { update = update, hide = hide }
end

return GuidePath
