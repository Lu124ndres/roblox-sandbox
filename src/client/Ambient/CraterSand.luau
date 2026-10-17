--!strict
--[[
	CraterSand

	El desierto del volcán cuando el monstruo es el minotauro (GiantDef.sand),
	en lugar del lago. Como la lava (CraterLava), local de cada cliente:
		rise()  la arena llena el pozo: cae en cortinas desde el acantilado y
		        sube un disco de arena del ancho del pozo (SandDisc), que empuja
		        hacia arriba los props del hábitat (SandProps); al llegar se
		        asienta: se escribe el terreno con dunas, ondas y rocas
		        (SandTerrain), nube de polvo y asoman los huesos (SandDecor).
		sink()  en el descanso se escurre por el centro, como un reloj de arena:
		        el terreno se vuelve disco, que baja con los props mientras un
		        remolino de polvo gira en el medio.
	La superficie queda en waterLevel (más dunas): ahí apoya los pies el
	minotauro, igual que en el agua. Se puede pisar; quien cae lo rescata
	AbyssRescue al rato.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local SandDecor = require(script.Parent.SandDecor)
local SandDisc = require(script.Parent.SandDisc)
local SandFx = require(script.Parent.SandFx)
local SandProps = require(script.Parent.SandProps)
local SandTerrain = require(script.Parent.SandTerrain)

local L = WorldLayout
local CYCLE = Config.Giants.cycle
local TOP = L.waterLevel
local BOTTOM = L.craterFloor + 2
local CENTER = WorldZones.craterCenter
local POURS = 10 -- cortinas de arena alrededor del acantilado al llenarse
local SETTLE_SECONDS = 0.4 -- lo que tarda en escribirse el terreno (cuatro cuadros) y asentarse

local CraterSand = {}

local level = BOTTOM -- dónde está ahora la arena (el disco, o TOP si ya es terreno)
local generation = 0

-- La arena a la altura y: el disco ahí y los props apoyados encima.
local function place(y: number)
	level = y
	SandDisc.place(y)
	SandProps.setDepth(TOP - y)
end

local function rumble(strength: number)
	local character = Players.LocalPlayer.Character
	local near = if character then WorldZones.craterBlend(character:GetPivot().Position) else 0
	CameraShake.shake(strength * (0.3 + 0.7 * near), 1)
	Sounds.play("Thunder", CENTER + Vector3.new(0, TOP, 0), 0.45)
end

-- Mueve la arena de donde está a `to` en `seconds` (con ease) y al final llama a after.
local function move(to: number, seconds: number, ease: (number) -> number, after: () -> ())
	local mine = generation
	local from = level
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if mine ~= generation then
			connection:Disconnect()
			return
		end
		elapsed = math.min(elapsed + dt, seconds)
		place(from + (to - from) * ease(elapsed / seconds))
		if elapsed >= seconds then
			connection:Disconnect()
			after()
		end
	end)
end

-- La arena ya arriba: terreno con dunas en vez del disco, y todo apoyado.
local function settle(instant: boolean)
	local mine = generation
	local written = SandTerrain.write(instant, function(): boolean
		return mine == generation
	end)
	if mine ~= generation then
		return -- mientras se escribía empezó a irse
	end
	level = TOP
	SandProps.setDepth(0)
	if written then
		SandDisc.hide()
	else
		SandDisc.place(TOP) -- sin terreno todavía: queda el disco, que también se pisa
	end
	SandDecor.show(instant)
	if not instant then
		for k = 1, 8 do -- se asienta: polvo por todo el desierto
			local a = k / 8 * math.pi * 2
			local r = if k % 2 == 0 then 60 else 140
			SandFx.puff(CENTER + Vector3.new(math.cos(a) * r, TOP + 1, math.sin(a) * r), 4)
		end
		SandFx.ring(CENTER + Vector3.new(0, TOP, 0), L.craterLakeRadius)
		rumble(0.25)
	end
end

function CraterSand.rise(instant: boolean)
	generation += 1
	SandDisc.swirl(false)
	if instant then
		task.spawn(settle, true)
		return
	end
	local seconds = CYCLE.refillSeconds * 1.5 -- como la lava
	rumble(0.5)
	for k = 1, POURS do -- cortinas de arena que caen del borde
		local a = (k + math.random() * 0.5) / POURS * math.pi * 2
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local lip = CENTER + out * (L.craterCliffRadius - 4) + Vector3.new(0, L.craterRimHeight, 0)
		SandFx.pour(lip, -out, seconds * 0.8)
	end
	place(level)
	move(TOP, seconds - SETTLE_SECONDS, function(t: number)
		return 1 - (1 - t) ^ 2 -- rápido al empezar, frena al llenarse
	end, function()
		task.spawn(settle, false)
	end)
end

function CraterSand.sink(instant: boolean)
	generation += 1
	SandDecor.hide()
	SandTerrain.clear()
	if instant then
		SandDisc.hide()
		level = BOTTOM
		SandProps.setDepth(math.huge)
		return
	end
	place(TOP)
	SandDisc.swirl(true)
	rumble(0.45)
	SandFx.ring(CENTER + Vector3.new(0, TOP, 0), L.craterLakeRadius * 0.7)
	SandFx.puff(CENTER + Vector3.new(0, TOP + 2, 0), 6)
	move(BOTTOM, CYCLE.drainSeconds, function(t: number)
		return t * t -- se escurre cada vez más rápido
	end, function()
		SandDisc.hide()
		SandProps.setDepth(math.huge)
	end)
end

return table.freeze(CraterSand)
