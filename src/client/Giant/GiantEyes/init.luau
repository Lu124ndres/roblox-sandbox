--!strict
--[[
	GiantEyes

	Pupilas por código que siguen al jugador local: cada cliente ve que el gigante
	lo mira a él. Es cosmético y local; no pasa nada por la red.
		start()        sigue a cada gigante que aparece en Workspace (lo llama Main).
		follow(model)  model: el exterior de GiantBody, que contiene la etapa.
		               Devuelve la limpieza.
	Sigue los cambios de etapa (GiantBody.dress reemplaza el hijo Model) y busca
	los datos por el nombre del modelo interno (UIConfig.GiantEyesData). Sin datos,
	sin el hueso, sin MeshPart o sin requiresBone, no hace nada.
	Corre en BindToRenderStep con prioridad Last, después de la cámara y de quien
	mueve el gigante. Lejos de la cámara recalcula la mirada menos seguido y, más
	lejos, esconde las pupilas (UIConfig.GiantEyes, en "lados de ojo").
	Partes: GiantEyes/Montaje. Mirada: GiantEyes/Mirar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Settings = require(ReplicatedStorage.Shared.UIConfig.GiantEyes)
local Distance = require(script.Parent.Parent.Effects.Distance)
local Mirar = require(script.Mirar)
local Montaje = require(script.Montaje)

local GiantEyes = {}

local bound = 0 -- para que cada gigante tenga su nombre en BindToRenderStep

-- La cabeza del personaje local o, si no hay, la cámara.
local function targetPosition(): Vector3?
	local player = Players.LocalPlayer
	local character = player and player.Character
	local head = character and character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end
	local camera = Workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function seedOf(name: string): number
	local seed = 0
	for i = 1, #name do
		seed = (seed * 31 + string.byte(name, i)) % 9973
	end
	return seed + bound
end

function GiantEyes.follow(model: Model): () -> ()
	bound += 1
	local bindName = `GiantEyes{bound}`
	local memo = Mirar.new(seedOf(model.Name))
	local rig: Montaje.Montaje? = nil
	local dirty = true -- cambió la etapa: hay que volver a armar
	local hidden = false
	local pending = 0 -- s sin recalcular la mirada (lejos)
	local connections: { RBXScriptConnection } = {}
	local done = false

	local function rebuild()
		dirty, hidden, pending = false, false, 0
		if rig then
			Montaje.destroy(rig)
			rig = nil
		end
		local inner = model:FindFirstChildWhichIsA("Model")
		if inner then
			rig = Montaje.build(inner)
		end
	end

	local function step(dt: number)
		if dirty then
			rebuild()
		end
		local r = rig
		if not r then
			return
		end
		if not r.part:IsDescendantOf(model) then -- la etapa se fue sin aviso
			dirty = true
			return
		end
		local frames = Montaje.eyes(r)
		local first = frames[1]
		if not first then
			return
		end
		-- Qué tan lejos está, en lados de ojo (con efectos reducidos, los cortes se acercan).
		local ratio = Distance.fromCamera(first.Position) / (r.minSide * Distance.scale())
		local stop = Settings.StopRatio * (if hidden then 1 - Settings.StopHysteresis else 1)
		local far = ratio > stop
		if far ~= hidden then
			hidden = far
			Montaje.setHidden(r, far)
		end
		if far then
			return
		end
		pending += dt
		if ratio <= Settings.MidRatio or pending >= Settings.MidSeconds then
			Mirar.step(memo, frames, targetPosition(), pending, os.clock())
			pending = 0
		end
		Montaje.place(r, frames, memo.out)
	end

	local function cleanup()
		if done then
			return
		end
		done = true
		RunService:UnbindFromRenderStep(bindName)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		if rig then
			Montaje.destroy(rig)
			rig = nil
		end
	end

	local function onChild(child: Instance)
		if child:IsA("Model") then
			dirty = true
		end
	end
	table.insert(connections, model.ChildAdded:Connect(onChild))
	table.insert(connections, model.ChildRemoved:Connect(onChild))
	table.insert(connections, model.Destroying:Connect(cleanup))
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value, step)
	return cleanup
end

-- Sigue solo a cada gigante que GiantBody.spawn pone en Workspace (un Model con el id
-- de su GiantDef): así GiantBody no necesita saber de las pupilas.
function GiantEyes.start()
	local ids: { [string]: boolean } = {}
	for _, def in Config.Giants.chain do
		ids[def.id] = true
	end
	local function onChild(child: Instance)
		if child:IsA("Model") and ids[child.Name] then
			GiantEyes.follow(child) -- se limpia sola con child.Destroying
		end
	end
	Workspace.ChildAdded:Connect(onChild)
	for _, child in Workspace:GetChildren() do
		onChild(child)
	end
end

return table.freeze(GiantEyes)
