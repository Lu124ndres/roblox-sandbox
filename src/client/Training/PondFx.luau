--!strict
--[[
	PondFx

	Vida de los estanques de entrenamiento (las piezas vienen del mapa,
	tools/estanques):
		- el espíritu del estanque (la esfera de luz sobre el loto del centro)
		  flota y suelta destellos de su color;
		- desde el estanque 7, tres luciérnagas vuelan a su alrededor;
		- si el jugador todavía no lo desbloqueó, el espíritu se ve apagado y
		  quieto, sin destellos: de un vistazo se sabe a cuáles puede entrar.
	Los kois, las rocas que flotan y la bruma de la cascada son de PondLife.
	Solo se animan los estanques cerca de la cámara (PondAnimateDistance), y
	los destellos de los lejanos se apagan.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Perks = require(ReplicatedStorage.Shared.Perks)
local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

local ANIMATE_DISTANCE = Performance.PondAnimateDistance
-- Bloqueado: del color del estanque pero liso (sin neón, destellos ni luz).
local LOCKED_MATERIAL = Enum.Material.SmoothPlastic

type Pond = {
	index: number,
	spirit: BasePart,
	base: CFrame,
	color: Color3,
	orbiters: { BasePart },
	sparkles: ParticleEmitter,
	light: PointLight?,
	open: boolean, -- desbloqueado por el jugador
	near: boolean, -- cerca de la cámara
}

local PondFx = {}

local function sparklesFor(spirit: BasePart, color: Color3): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = Assets.Particles.Sparkle
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(1, 1.8)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -2, 0)
	emitter.Rate = 10
	emitter.Parent = spirit
	FxQuality.scaleEmitter(emitter)
	return emitter
end

local function collect(map: Instance): { Pond }
	local ponds = {}
	for _, descendant in map:GetDescendants() do
		local index = descendant:GetAttribute(Protocol.Map.PondIndexAttribute)
		if
			descendant.Name == "Espiritu"
			and descendant:IsA("BasePart")
			and type(index) == "number"
		then
			local orbiters = {}
			for k = 1, 3 do
				local orbiter = descendant.Parent
					and descendant.Parent:FindFirstChild(`Luciernaga{k}`)
				if orbiter and orbiter:IsA("BasePart") then
					table.insert(orbiters, orbiter)
				end
			end
			table.insert(ponds, {
				index = index,
				spirit = descendant,
				base = descendant.CFrame,
				color = descendant.Color,
				orbiters = orbiters,
				sparkles = sparklesFor(descendant, descendant.Color),
				light = descendant:FindFirstChildOfClass("PointLight"),
				open = false,
				near = true,
			})
		end
	end
	return ponds
end

function PondFx.start()
	local player = Players.LocalPlayer
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local ponds = collect(map)

	-- force: pintar todo (al empezar); si no, solo los que cambiaron (el poder sube cada tick).
	local function refreshLocks(force: boolean?)
		for _, pond in ponds do
			local open = Perks.pondOpen(player, pond.index)
			if not force and open == pond.open then
				continue
			end
			pond.spirit.Color = pond.color
			pond.spirit.Material = if open then Enum.Material.Neon else LOCKED_MATERIAL
			pond.open = open
			pond.sparkles.Enabled = open and pond.near
			if pond.light then
				pond.light.Enabled = open
			end
			pond.spirit:SetAttribute("Abierto", open)
		end
	end
	player.AttributeChanged:Connect(function(name: string)
		if Perks.affectsPonds(name) then
			refreshLocks()
		end
	end)
	refreshLocks(true)

	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		local t = os.clock()
		for _, pond in ponds do
			local near = (camera.CFrame.Position - pond.base.Position).Magnitude < ANIMATE_DISTANCE
			if near ~= pond.near then
				pond.near = near
				pond.sparkles.Enabled = pond.open and near
			end
			if near then
				local open = pond.open
				local bob = if open then math.sin(t * 1.6 + pond.index) * 0.45 else 0
				local spin = if open then t * 0.8 else 0
				pond.spirit.CFrame = CFrame.new(pond.base.Position + Vector3.new(0, bob, 0))
					* CFrame.Angles(0, spin, 0)
					* pond.base.Rotation
				for k, orbiter in pond.orbiters do
					local angle = t * 1.4 + k * math.pi * 2 / 3
					local offset = Vector3.new(
						math.cos(angle) * 2.8,
						math.sin(t * 2 + k) * 0.6,
						math.sin(angle) * 2.8
					)
					orbiter.CFrame = CFrame.new(pond.base.Position + offset)
						* CFrame.Angles(t * 2, t * 3, 0)
				end
			end
		end
	end)
end

return PondFx
