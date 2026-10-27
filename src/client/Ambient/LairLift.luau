--!strict
--[[
	LairLift

	Sube y hunde las rocas de la guarida volcánica (con el nido y sus
	cristales) junto con la lava, en este cliente. Las rocas van siempre a
	la altura de la lava (level) y además hundidas DEPTH * (1 - emerge):
	con emerge en 0 quedan bajo la superficie (y ni están en el Workspace),
	en 1 la cima queda justo donde dice Dragon/Guarida. emerge se anima con
	go() (un Heartbeat solo mientras se mueve) y se mueven todas juntas con
	BulkMoveTo. Al romper la superficie, salpican fuego alrededor.
	Las mallas del hábitat completo que suben (LairMeshes) bajan lo mismo, y
	con emerge en 0 se esconden. refresh() vuelve a leer qué piezas hay en la
	carpeta (LavaLair saca o pone las primitivas según haya hábitat completo).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local LairMeshes = require(script.Parent.LairMeshes)
local LairParts = require(script.Parent.LairParts)

local LAVA = Guarida.lava
local DEPTH = 34 -- studs bajo la superficie: ni la cima del nido asoma
local BREAK = 0.4 -- emerge con el que la cima de la roca central rompe la superficie

local LairLift = {}

local folder: Instance? = nil
local home: Instance? = nil
local parts: { BasePart } = {}
local restOf: { [BasePart]: CFrame } = {} -- dónde se armó cada pieza (su lugar final)
local frames: { CFrame } = {}
local level = LAVA
local emerge, from, to, startAt, seconds = 0, 0, 0, 0, 1
local splashed = true -- ya salpicó en esta subida (o no sube)
local connection: RBXScriptConnection? = nil

local function apply()
	local e = emerge * emerge * (3 - 2 * emerge)
	local down = Vector3.new(0, (LAVA - level) + DEPTH * (1 - e), 0)
	LairMeshes.place(down, emerge > 0)
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
	for i, part in parts do
		frames[i] = restOf[part] - down
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

local function stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Fuego que salta alrededor de cada roca al salir de la lava.
local function splashOut()
	for _, perch in Guarida.perches do
		local top = Guarida.point(perch)
		for k = 1, 5 do
			local a = k / 5 * math.pi * 2
			local rim = Vector3.new(
				top.X + math.cos(a) * perch.size,
				LAVA + 1,
				top.Z + math.sin(a) * perch.size
			)
			Fx.sparkle(rim, LairParts.MAGMA_HOT, 16)
		end
	end
end

-- Retumbo del volcán: más fuerte si el jugador está en el cráter.
function LairLift.rumble(strength: number)
	local character = Players.LocalPlayer.Character
	local near = if character then WorldZones.craterBlend(character:GetPivot().Position) else 0
	CameraShake.shake(strength * (0.3 + 0.7 * near), 1.2)
	Sounds.play("Thunder", LairParts.CENTER + Vector3.new(0, LAVA, 0), 0.5)
end

-- Las piezas de `rocks` (ya armadas en su lugar final) se moverán dentro de `parent`.
function LairLift.track(rocks: Instance, parent: Instance)
	folder, home = rocks, parent
	LairLift.refresh()
end

-- Vuelve a juntar las piezas que hay ahora en la carpeta (cada una recuerda dónde se armó).
function LairLift.refresh()
	local target = folder
	if not target then
		return
	end
	table.clear(parts)
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then
			if not restOf[d] then
				restOf[d] = d.CFrame
			end
			table.insert(parts, d)
		end
	end
	frames = table.create(#parts)
	apply()
end

function LairLift.level(y: number)
	level = y
	apply()
end

-- De una: emerge en value y la lava en su lugar.
function LairLift.snap(value: number)
	stop()
	level, emerge = LAVA, value
	apply()
end

-- emerge va a `target` en `duration` segundos, después de `delay`.
function LairLift.go(target: number, duration: number, delay: number)
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
			LairLift.rumble(0.5)
		end
		if t >= 1 then
			stop()
		end
	end)
end

apply() -- las mallas del hábitat que lleguen antes que la lava, ya hundidas

return table.freeze(LairLift)
