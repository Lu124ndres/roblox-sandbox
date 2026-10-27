--!strict
--[[
	GuaridaSube

	La guarida del descanso (Workspace.GuaridaDescanso, la pone RestArena) sube
	desde el fondo del volcán mientras el lago se vacía y se hunde al terminar el
	descanso, en este cliente: el servidor la mueve de una vez (así se pisa bien)
	y aquí se anima la subida, suave y sin cargar la red (BulkMoveTo).
	Al subir: retumbo, brasas en el borde y, al llegar, una onda de polvo; al
	bajar, otro retumbo. Quien entra con el descanso ya empezado la ve en su lugar.
	"Arriba" se mide con el piso (Piso, a restArenaTop: flota sobre el relleno, que
	en el descanso se queda): no importa si el servidor ya la movió cuando llega
	el aviso.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)

local L = WorldLayout
local HIDDEN_Y = L.restArenaTop - L.restArenaSink -- piso enterrado, mientras se alimenta
local LAVA = Color3.fromRGB(255, 120, 30)
local CENTER = WorldZones.craterCenter
local SINK_SECONDS = 5

local GuaridaSube = {}

local generation = 0

local function ease(t: number): number
	t = math.clamp(t, 0, 1)
	return 1 - (1 - t) ^ 3 -- rápido al empezar, se asienta al final (peso)
end

-- Las piezas y su lugar "arriba"; nil si la guarida no está.
local function snapshot(top: number): ({ BasePart }?, { CFrame }?)
	local arena = Workspace:FindFirstChild(Protocol.Map.RestArena)
	local floor = arena and arena:FindFirstChild("Piso", true)
	if not (arena and floor and floor:IsA("BasePart")) then
		return nil, nil
	end
	local lift = Vector3.new(0, top - 0.1 - floor.Position.Y, 0) -- el Piso, arriba
	local parts, up = {}, {}
	for _, d in arena:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(up, d.CFrame + lift)
		end
	end
	return parts, up
end

local function rumble(strength: number)
	local character = game:GetService("Players").LocalPlayer.Character
	local near = if character then WorldZones.craterBlend(character:GetPivot().Position) else 0
	CameraShake.shake(strength * (0.3 + 0.7 * near), 1.2)
	Sounds.play("Thunder", CENTER + Vector3.new(0, L.restArenaTop, 0), 0.5)
end

-- rising: sube (enterrada → arriba) o se hunde (arriba → enterrada) en `seconds`.
local function animate(rising: boolean, seconds: number)
	local top = L.restArenaTop
	generation += 1
	local mine = generation
	local travel = top - HIDDEN_Y
	local parts, up = snapshot(top)
	if not parts or not up then
		return
	end
	local frames = table.create(#parts) :: { CFrame }
	local start = os.clock()
	local nextSpark = 0
	rumble(if rising then 0.6 else 0.4)
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if mine ~= generation then
			connection:Disconnect()
			return
		end
		local t = (os.clock() - start) / seconds
		local e = ease(t)
		local down = if rising then travel * (1 - e) else travel * e
		for i, cf in up do
			frames[i] = cf - Vector3.new(0, down, 0)
		end
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		local now = os.clock()
		if rising and now > nextSpark and t < 1 then -- brasas que saltan del borde al subir
			nextSpark = now + 0.35
			local a = math.random() * math.pi * 2
			local rim = CENTER
				+ Vector3.new(math.cos(a), 0, math.sin(a)) * L.restArenaRadius
				+ Vector3.new(0, top - down, 0)
			Fx.sparkle(rim, LAVA, 10)
		end
		if t >= 1 then
			connection:Disconnect()
			if rising then -- llega: polvo y una onda que recorre el piso
				local floor = CENTER + Vector3.new(0, top + 0.5, 0)
				Fx.ring(floor, L.restArenaRadius, 1.6)
				CameraShake.shake(0.25, 0.6)
			end
		end
	end)
end

-- Escucha VolcanVacio: true = sube durante el vaciado; false = se hunde.
function GuaridaSube.watch(stateFolder: Instance)
	local ATTR = Protocol.GiantAttributes
	local was = stateFolder:GetAttribute(ATTR.Drained) == true
	stateFolder:GetAttributeChangedSignal(ATTR.Drained):Connect(function()
		local now = stateFolder:GetAttribute(ATTR.Drained) == true
		if now ~= was then
			was = now
			animate(now, if now then Config.Giants.cycle.drainSeconds else SINK_SECONDS)
		end
	end)
end

return table.freeze(GuaridaSube)
