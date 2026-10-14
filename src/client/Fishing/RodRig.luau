--!strict
--[[
	RodRig

	La caña y el brazo de cada jugador según su nivel de detalle
	(Effects/Distance; el jugador local siempre "near"):
		near  caña cada cuadro, brazo animado, ondas y adornos encendidos
		mid   caña a RodMidUpdateSeconds, brazo quieto, sin ondas ni adornos
		far   sin caña, sedal ni corcho (FishingVisuals no los crea)

	Guardar la caña no la destruye: queda sin padre y se reutiliza la
	próxima vez si es la misma caña y el mismo personaje. Solo se destruye
	al cambiar de personaje o al irse el jugador. Un único RenderStepped
	mueve las cañas de todos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local Upgrades = require(ReplicatedStorage.Shared.Upgrades)
local Distance = require(script.Parent.Parent.Effects.Distance)
local ArmPose = require(script.Parent.ArmPose)
local Rod = require(script.Parent.Rod)
local RigParts = require(script.Parent.RigParts)

type Rig = RigParts.Rig
type Entry = {
	rig: Rig,
	stowed: Rod.Rod?, -- caña guardada sin padre, lista para reutilizar
	character: Model?, -- personaje para el que se armó la caña guardada
	full: boolean, -- nivel "near"
	since: number, -- segundos desde la última vez que se movió la caña
}

local HOLD_DEGREES = 60 -- ángulo del brazo si no hay pose

local RodRig = {}

local entries: { [Player]: Entry } = {}
local loop: RBXScriptConnection? = nil

local function step(dt: number)
	for _, entry in entries do
		local rod, pose = entry.rig.rod, entry.rig.pose
		if rod then
			entry.since += dt
			if entry.full or entry.since >= Performance.RodMidUpdateSeconds then
				entry.since = 0
				rod.follow(if pose then pose.angle() else HOLD_DEGREES)
			end
		end
	end
end

local function entryFor(player: Player, rig: Rig): Entry
	local entry = entries[player]
	if not entry then
		entry = { rig = rig, full = true, since = 0 }
		entries[player] = entry
	end
	if not loop then
		loop = RunService.RenderStepped:Connect(step)
	end
	return entry
end

-- Enciende o apaga lo caro según el nivel actual del jugador.
function RodRig.applyTier(player: Player, rig: Rig)
	local entry = entryFor(player, rig)
	entry.full = Distance.tier(player) == "near"
	if rig.pose then
		rig.pose.setActive(entry.full)
	end
	if rig.rod then
		rig.rod.setDetail(entry.full)
	end
	if rig.bobber then
		rig.bobber.setRipples(entry.full)
	end
end

-- Saca la caña (reutiliza la guardada si sirve). Devuelve false si el
-- jugador está lejos y no se dibuja nada; built = true si se armó una nueva.
function RodRig.show(player: Player, rig: Rig, character: Model): (boolean, boolean)
	if Distance.tier(player) == "far" then
		RodRig.stow(player, rig)
		return false, false
	end
	local entry = entryFor(player, rig)
	local built = false
	if not rig.pose then
		rig.pose = ArmPose.new(character)
	end
	if not rig.rod then
		local look = Upgrades.level(player, "Rod")
		local stowed = entry.stowed
		entry.stowed = nil
		if stowed and stowed.look == look and entry.character == character then
			stowed.model.Parent = character
			rig.rod = stowed
		else
			if stowed then
				stowed.model:Destroy()
			end
			rig.rod = Rod.attach(character, look)
			entry.character = character
			built = true
		end
	end
	RodRig.applyTier(player, rig)
	return true, built
end

-- Guarda la caña sin destruirla y suelta el brazo. El sedal va con el
-- corcho: quien llama limpia el corcho antes (RigParts.clearBobber).
function RodRig.stow(player: Player, rig: Rig)
	local entry = entries[player]
	if rig.rod and entry then
		if entry.stowed then
			entry.stowed.model:Destroy()
		end
		rig.rod.model.Parent = nil
		entry.stowed = rig.rod
		rig.rod = nil
	end
	RigParts.dropRod(rig) -- solo queda el brazo (y la caña si no había entrada)
end

-- Destruye todo: cambio de personaje o el jugador se fue.
function RodRig.release(player: Player, rig: Rig, leaving: boolean?)
	RigParts.dropRod(rig)
	local entry = entries[player]
	if entry and entry.stowed then
		entry.stowed.model:Destroy()
		entry.stowed = nil
	end
	if leaving then
		entries[player] = nil
	end
end

return RodRig
