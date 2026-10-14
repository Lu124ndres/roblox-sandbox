--!strict
--[[
	Distance

	Nivel de detalle de los OTROS jugadores según su distancia a la cámara
	(UIConfig.Performance):
		near  más cerca que TierNear: todo el detalle
		mid   entre TierNear y TierMid: sin adornos caros
		far   más lejos que TierMid: casi nada
	Con efectos reducidos los cortes se acercan (LowFxDistanceScale). Se
	recalcula cada TierUpdateSeconds con un margen (histéresis), así un
	jugador justo en el borde no cambia de nivel a cada rato. El jugador
	local siempre es "near".

	Arranca solo la primera vez que alguien lo usa.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

export type Tier = "near" | "mid" | "far"
type Listener = (player: Player, tier: Tier) -> ()

local Distance = {}

local tiers: { [Player]: Tier } = {}
local listeners: { [number]: Listener } = {}
local nextListener = 0
local started = false

-- Multiplicador de todas las distancias de detalle (más corto con efectos reducidos).
function Distance.scale(): number
	return if ClientSettings.get("lowFx") then Performance.LowFxDistanceScale else 1
end

function Distance.fromCamera(position: Vector3): number
	local camera = Workspace.CurrentCamera
	return if camera then (camera.CFrame.Position - position).Magnitude else 0
end

local function positionOf(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- Para ganar detalle hay que acercarse un poco más que el corte; para
-- perderlo, alejarse un poco más.
local function classify(current: Tier?, distance: number): Tier
	local s = Distance.scale()
	local near, mid, margin =
		Performance.TierNear * s, Performance.TierMid * s, Performance.TierHysteresis * s
	if current == "near" then
		near, mid = near + margin, mid + margin
	elseif current == "mid" then
		near, mid = near - margin, mid + margin
	elseif current == "far" then
		near, mid = near - margin, mid - margin
	end
	if distance < near then
		return "near"
	elseif distance < mid then
		return "mid"
	end
	return "far"
end

local function measure(player: Player): Tier
	local position = positionOf(player)
	if not position then
		return "far"
	end
	return classify(tiers[player], Distance.fromCamera(position))
end

local function step()
	for _, player in Players:GetPlayers() do
		if player ~= Players.LocalPlayer then
			local before: Tier? = tiers[player]
			local tier: Tier = measure(player)
			tiers[player] = tier
			if before and before ~= tier then
				for _, callback in listeners do
					task.spawn(callback, player, tier)
				end
			end
		end
	end
end

local function ensureStarted()
	if started then
		return
	end
	started = true
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= Performance.TierUpdateSeconds then
			elapsed = 0
			step()
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		tiers[player] = nil
	end)
	ClientSettings.onChanged(function(key: string)
		if key == "lowFx" then
			step()
		end
	end)
end

function Distance.tier(player: Player): Tier
	if player == Players.LocalPlayer then
		return "near"
	end
	ensureStarted()
	local cached: Tier? = tiers[player]
	if cached then
		return cached
	end
	local tier: Tier = measure(player)
	tiers[player] = tier
	return tier
end

-- Avisa cada vez que un jugador cambia de nivel. Devuelve cómo dejar de escuchar.
function Distance.onChanged(callback: Listener): () -> ()
	ensureStarted()
	nextListener += 1
	local id = nextListener
	listeners[id] = callback
	return function()
		listeners[id] = nil
	end
end

return Distance
