--!strict
--[[
	IceLift

	Sube y hunde lo que flota en el lago del zorro (los témpanos y las rocas,
	IceLair), en este cliente. Cada pieza va hundida DEPTH * (1 - emerge): con
	emerge en 0 queda bajo el abismo del lago (y ni está en el Workspace), en 1
	queda en su lugar (la cima de cada témpano grande donde dice Zorro/Guarida).
	emerge se anima con go() (un Heartbeat solo mientras se mueve) y se mueven
	todas juntas con BulkMoveTo. Al romper la superficie, el agua salpica
	alrededor de cada lugar del contrato.
	También mueve la banquisa del hábitat completo (IceHabitat.floating, float()):
	es del servidor, así que no se saca del Workspace; con emerge en 0 queda
	hundida e invisible en este cliente (LocalTransparencyModifier).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Guarida = require(ReplicatedStorage.Shared.Zorro.Guarida)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local Fx = require(script.Parent.Parent.Effects.Fx)

local DEPTH = 32 -- studs bajo la superficie: ni la cima de la roca de vigía asoma
local BREAK = 0.7 -- emerge con el que los témpanos ya casi rompen la superficie
local SPLASH_POINTS = 5 -- salpicones alrededor de cada lugar

local IceLift = {}

local folder: Instance? = nil
local home: Instance? = nil
local parts: { BasePart } = {}
local rest: { CFrame } = {}
local frames: { CFrame } = {}
local extra: { BasePart } = {} -- la banquisa del hábitat completo (del servidor)
local restOf: { [BasePart]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
local emerge, from, to, startAt, seconds = 0, 0, 0, 0, 1
local splashed = true -- ya salpicó en esta subida (o no sube)
local connection: RBXScriptConnection? = nil

-- Mueve la banquisa del hábitat completo (la que siga en el Workspace).
local function applyExtra(down: Vector3)
	local moving: { BasePart }, targets: { CFrame } = {}, {}
	local hidden = if emerge > 0 then 0 else 1
	for _, part in extra do
		if part:IsDescendantOf(Workspace) then
			part.LocalTransparencyModifier = hidden
			table.insert(moving, part)
			table.insert(targets, restOf[part] - down)
		end
	end
	if #moving > 0 then
		Workspace:BulkMoveTo(moving, targets, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function apply()
	local e = emerge * emerge * (3 - 2 * emerge)
	local down = Vector3.new(0, DEPTH * (1 - e), 0)
	applyExtra(down)
	local target = folder
	if not target then
		return
	end
	local wanted = if emerge > 0 then home else nil
	if target.Parent ~= wanted then
		target.Parent = wanted
	end
	if emerge <= 0 then
		return
	end
	for i, cframe in rest do
		frames[i] = cframe - down
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- El agua se abre alrededor de cada témpano grande y de la roca al salir.
local function splashOut()
	for _, spot in Guarida.spots do
		local top = Guarida.point(spot)
		local water = Vector3.new(top.X, Guarida.water, top.Z)
		Fx.ring(water, spot.size * 1.6, 1.4)
		for k = 1, SPLASH_POINTS do
			local a = k / SPLASH_POINTS * math.pi * 2
			Fx.splash(water + Vector3.new(math.cos(a), 0, math.sin(a)) * spot.size, 2)
		end
		Sounds.play("BigSplash", water, 0.7)
	end
end

-- Las piezas de `floating` (ya armadas en su lugar final) se moverán dentro de `parent`.
-- Reemplaza lo que se seguía antes (IceLair rearma el lago si cambia el hábitat).
function IceLift.track(floating: Instance, parent: Instance)
	folder, home = floating, parent
	table.clear(parts)
	table.clear(rest)
	for _, d in floating:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(rest, d.CFrame)
		end
	end
	frames = table.create(#parts)
	apply()
end

-- La banquisa del hábitat completo: piezas del servidor en su lugar final (la primera
-- vez que se ven; después ya las movió este cliente). Lista vacía si no hay hábitat.
function IceLift.float(list: { BasePart })
	extra = list
	for _, part in list do
		if not restOf[part] then
			restOf[part] = part.CFrame
		end
	end
	apply()
end

-- De una: emerge en value.
function IceLift.snap(value: number)
	stop()
	emerge = value
	apply()
end

-- emerge va a `target` en `duration` segundos, después de `delay`.
function IceLift.go(target: number, duration: number, delay: number)
	from, to, startAt, seconds = emerge, target, os.clock() + delay, duration
	splashed = not (from < BREAK and to >= 1)
	if connection then
		return
	end
	connection = RunService.Heartbeat:Connect(function()
		local t = math.clamp((os.clock() - startAt) / seconds, 0, 1)
		emerge = from + (to - from) * t
		apply()
		if not splashed and emerge >= BREAK then
			splashed = true
			splashOut()
		end
		if t >= 1 then
			stop()
		end
	end)
end

return table.freeze(IceLift)
