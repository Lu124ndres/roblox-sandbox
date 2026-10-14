--!strict
--[[
	GiantMood

	El gigante se enoja si nadie le da de comer:
		- Pasados graceSeconds sin un bocado (smallServerGraceSeconds con
		  pocos jugadores), el enojo sube de 0 a 1 en
		  rampSeconds y se publica en EstadoGigante.Anger.
		- Desde angryThreshold, el hambre vuelve: la barra baja sola, pero
		  nunca por debajo del inicio de la etapa actual (no encoge).
		- Furioso (1): cada attackIntervalSeconds lanza un Salpicón contra un
		  jugador cerca del cráter. Todos ven el círculo de aviso durante
		  telegraphSeconds; quien siga dentro (menos un margen por ping) recibe
		  un empujón. Nunca se pierde nada.
	Un solo bocado lo calma (GiantService.feed pone el enojo en 0).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FishingService = require(script.Parent.FishingService)
local GiantService = require(script.Parent.GiantService)
local Proximity = require(script.Parent.Proximity)
local Remotes = require(script.Parent.Remotes)

local ANGER = Config.Giants.anger
local TICK_SECONDS = 0.5
local ANGER_STEP = 0.02 -- se publica en pasos para no mandar atributos a cada rato

local GiantMood = {}

local rng = Random.new()
local nextAttackAt = 0

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Jugadores vivos y en el suelo cerca del cráter: los únicos que pueden recibir un Salpicón.
local function targetsNearCrater(): { BasePart }
	local center = GiantService.getCenter()
	local roots = {}
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		if root and flatDistance(root.Position, center) <= ANGER.attackRangeStuds then
			table.insert(roots, root)
		end
	end
	return roots
end

local function resolveAttack(position: Vector3)
	if GiantService.getAnger() < 1 then
		return -- alguien lo calmó durante el aviso: el golpe no llega
	end
	local center = GiantService.getCenter()
	local reach = ANGER.attackRadiusStuds - ANGER.hitMarginStuds
	for _, player in Players:GetPlayers() do
		local root = Proximity.getRoot(player)
		if
			root
			and flatDistance(root.Position, position) <= reach
			and math.abs(root.Position.Y - position.Y) < 14
		then
			Remotes.GiantHit:FireClient(player, center)
			FishingService.interrupt(player) -- el pez que picaba se escapa; la canasta no se toca
		end
	end
end

local function attack()
	local roots = targetsNearCrater()
	if #roots == 0 then
		return
	end
	local root = roots[rng:NextInteger(1, #roots)]
	local position = root.Position - Vector3.new(0, 3, 0)
	Remotes.GiantAttack:FireAllClients(position, ANGER.attackRadiusStuds, ANGER.telegraphSeconds)
	task.delay(ANGER.telegraphSeconds, resolveAttack, position)
end

local function tick()
	if not GiantService.isFeeding() or #Players:GetPlayers() == 0 then
		GiantService.calm()
		return
	end
	-- Con pocos jugadores un viaje tarda más que la espera normal.
	local grace = if #Players:GetPlayers() <= ANGER.smallServerPlayers
		then ANGER.smallServerGraceSeconds
		else ANGER.graceSeconds
	local over = GiantService.secondsSinceFed() - grace
	local raw = math.clamp(over / ANGER.rampSeconds, 0, 1)
	local anger = if raw >= 1 then 1 else math.floor(raw / ANGER_STEP) * ANGER_STEP
	GiantService.setAnger(anger)

	if anger >= ANGER.angryThreshold then
		GiantService.starve(ANGER.hungerDecayPerSecond * TICK_SECONDS)
	end
	local now = os.clock()
	if anger >= 1 and now >= nextAttackAt then
		nextAttackAt = now + ANGER.attackIntervalSeconds
		attack()
	elseif anger < 1 then
		-- Al enfurecer da un respiro antes del primer golpe.
		nextAttackAt = now + ANGER.telegraphSeconds
	end
end

function GiantMood.init()
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			tick()
		end
	end)
end

return GiantMood
