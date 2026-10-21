--!strict
--[[
	OrcaMotion/Feeders

	Quién le da de comer al gigante, según los lotes de GiantFed (cada
	~0.25 s mientras alguien mantiene E/F o el botón). Da la dirección (desde
	el centro del lago, en el plano) hacia quien alimenta:
		- la de siempre (Minotauro, Dragón, Zorro): si están repartidos por
		  el borde, la del último que le dio;
		- por turnos (la orca, `turns`): de a uno, en el orden en que
		  empezaron; el de turno se queda `linger` s más después de su último
		  pez si nadie espera, y con otros esperando dura a lo sumo TURN_SECONDS.
	`incoming` estima cuándo llega el próximo pez a la boca (FeedThrow los
	suelta con cada lote y vuelan FeedThrowSeconds): la orca abre antes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(script.Parent.Parent.Parent.Protocol)
local UIConfig = require(script.Parent.Parent.Parent.UIConfig)

local HOLD_SECONDS = 1.3 -- sin lotes por este tiempo: ya no le da de comer
local SPREAD_LIMIT = 0.35 -- suma de direcciones más corta que esto: están repartidos
local LINGER_SECONDS = 3.5 -- por turnos: lo que se queda en la orilla (Comer lo cambia por etapa)
local TURN_SECONDS = 25 -- por turnos, con otros esperando: lo más que dura un turno
local PRESENT_STUDS = 30 -- el de turno se alejó más que esto de donde le daba: ya no está
local FLIGHT = UIConfig.Effects.FeedThrowSeconds -- lo que vuela cada pez
local SPREAD, MIN_GAP, MAX_GAP = 0.16, 0.045, 0.16 -- cómo FeedThrow reparte los de un lote
local MAX_QUEUED = 10 -- FeedThrow no dibuja más pendientes por jugador

export type Target = {
	userId: number,
	position: Vector3, -- donde estaba al tirar el último pez
	lastAt: number, -- os.clock del último lote
	present: boolean, -- sigue ahí (en el juego y cerca de donde le daba)
}
export type Feeders = {
	linger: number,
	direction: () -> Vector3?,
	target: () -> Target?, -- el de turno (solo por turnos)
	incoming: (after: number) -> (number?, Vector3?), -- próximo pez desde `after`: cuándo y de dónde
	destroy: () -> (),
}

type Feeder = { position: Vector3, at: number, since: number, arrivals: { number } }

local Feeders = {}

-- Cuándo llegará a la boca cada pez del lote (como los suelta FeedThrow).
local function addArrivals(arrivals: { number }, count: number, now: number)
	local n = math.clamp(math.floor(count), 0, MAX_QUEUED)
	local gap = math.clamp(SPREAD / math.max(n, 1), MIN_GAP, MAX_GAP)
	for k = 0, n - 1 do
		table.insert(arrivals, now + FLIGHT + k * gap)
	end
	while #arrivals > MAX_QUEUED * 2 do
		table.remove(arrivals, 1)
	end
end

function Feeders.watch(origin: Vector3, turns: boolean?): Feeders
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local giantFed = remotes:WaitForChild(Protocol.Remotes.GiantFed) :: RemoteEvent
	local feeders: { [number]: Feeder } = {}
	local queue: { number } = {} -- userIds en el orden en que empezaron
	local api: Feeders

	local connection = giantFed.OnClientEvent:Connect(function(batch: unknown)
		if type(batch) ~= "table" then
			return
		end
		local now = os.clock()
		for _, entry in batch :: { any } do
			local userId = type(entry) == "table" and entry.userId
			local player = type(userId) == "number" and Players:GetPlayerByUserId(userId)
			local character = player and player.Character
			if player and character then
				local feeder = feeders[player.UserId]
				if not feeder then
					feeder = { position = Vector3.zero, at = now, since = now, arrivals = {} }
					feeders[player.UserId] = feeder
					if turns then
						table.insert(queue, player.UserId)
					end
				end
				feeder.position, feeder.at = character:GetPivot().Position, now
				local count = entry.count
				addArrivals(feeder.arrivals, if type(count) == "number" then count else 1, now)
			end
		end
	end)

	local function forget(index: number)
		feeders[table.remove(queue, index) :: number] = nil
		local first = feeders[queue[1]]
		if index == 1 and first then
			first.since = os.clock() -- empieza su turno
		end
	end

	-- Ordena la fila: saca a los que se fueron y rota el turno que se alargó.
	local function tidy(now: number)
		for index = #queue, 2, -1 do
			if now - feeders[queue[index]].at > HOLD_SECONDS then
				forget(index)
			end
		end
		local first = feeders[queue[1]]
		if not first then
			return
		end
		local idle = now - first.at
		if idle > HOLD_SECONDS + api.linger or (idle > HOLD_SECONDS and #queue > 1) then
			forget(1)
		elseif #queue > 1 and now - first.since > TURN_SECONDS then
			table.insert(queue, table.remove(queue, 1) :: number) -- vuelve al final
			feeders[queue[1]].since = now
		end
	end

	local function flat(position: Vector3): Vector3?
		local v = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z)
		return if v.Magnitude > 1 then v.Unit else nil
	end

	local function target(): Target?
		if not turns then
			return nil
		end
		tidy(os.clock())
		local userId = queue[1]
		local feeder = userId and feeders[userId]
		if not feeder then
			return nil
		end
		local player = Players:GetPlayerByUserId(userId)
		local character = player and player.Character
		local here = character and character:GetPivot().Position
		return {
			userId = userId,
			position = feeder.position,
			lastAt = feeder.at,
			present = here ~= nil and (here - feeder.position).Magnitude < PRESENT_STUDS,
		}
	end

	local function direction(): Vector3?
		if turns then
			local current = target()
			return if current then flat(current.position) else nil
		end
		local now = os.clock()
		local sum, latest, latestAt = Vector3.zero, nil :: Vector3?, 0
		for userId, feeder in feeders do
			if now - feeder.at > HOLD_SECONDS then
				feeders[userId] = nil
				continue
			end
			local unit = flat(feeder.position)
			if unit then
				sum += unit
				if feeder.at > latestAt then
					latest, latestAt = unit, feeder.at
				end
			end
		end
		return if sum.Magnitude > SPREAD_LIMIT then sum.Unit else latest
	end

	local function incoming(after: number): (number?, Vector3?)
		local best, from = math.huge, nil
		local now = os.clock()
		for _, feeder in feeders do
			local arrivals = feeder.arrivals
			while arrivals[1] and arrivals[1] < now - 1 do
				table.remove(arrivals, 1)
			end
			for _, at in arrivals do
				if at >= after and at < best then
					best, from = at, feeder.position
				end
			end
		end
		return if from then best else nil, from
	end

	api = {
		linger = LINGER_SECONDS,
		direction = direction,
		target = target,
		incoming = incoming,
		destroy = function()
			connection:Disconnect()
		end,
	}
	return api
end

return table.freeze(Feeders)
