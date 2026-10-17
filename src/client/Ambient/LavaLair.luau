--!strict
--[[
	LavaLair

	La guarida volcánica del dragón: lo que acompaña al lago de lava
	(CraterLava) mientras el monstruo es el dragón. Local de cada cliente,
	como la lava. CraterLava avisa:
		arrive()  empieza a subir la lava: las cascadas y ríos (LairFalls)
		          empiezan a correr; las rocas de obsidiana (LairRocks) con el
		          nido (LairNest) suben con ella, sumergidas, y al final salen
		          de la lava salpicando fuego (LairLift). Con la lava arriba
		          aparecen los cristales de la repisa (LairCrystals), los
		          géiseres (LairGeysers), el aire (LairAir) y la repisa se
		          vuelve ceniza (LairGround).
		level(y)  la lava está a la altura y (cada cuadro mientras se mueve).
		leave()   la lava se va (descanso u otro monstruo): se apaga todo y las
		          rocas se hunden en la lava, más rápido que ella, para no
		          cruzarse con la guarida del descanso que sube.
	Se arma todo una sola vez, la primera vez que llega el dragón.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local LairAir = require(script.Parent.LairAir)
local LairCrystals = require(script.Parent.LairCrystals)
local LairFalls = require(script.Parent.LairFalls)
local LairGeysers = require(script.Parent.LairGeysers)
local LairGround = require(script.Parent.LairGround)
local LairLift = require(script.Parent.LairLift)
local LairNest = require(script.Parent.LairNest)
local LairParts = require(script.Parent.LairParts)
local LairRocks = require(script.Parent.LairRocks)

local RISE_SECONDS = Config.Giants.cycle.refillSeconds * 1.5 -- lo que tarda en subir la lava (CraterLava)
local EMERGE_DELAY = RISE_SECONDS * 0.6 -- las rocas empiezan a salir con la lava casi arriba
local EMERGE_SECONDS = 3.5
local SUBMERGE_SECONDS = 1.1 -- antes de que la guarida del descanso alcance a la lava

local LavaLair = {}

local root = Instance.new("Folder")
root.Name = "GuaridaVolcanica"
local falls = Instance.new("Folder")
falls.Name = "Cascadas"
local still = Instance.new("Folder") -- lo que aparece con la lava ya arriba
still.Name = "CristalesYGeiseres"

local built = false
local arrived = false -- la lava llegó: géiseres, aire y ceniza
local generation = 0

local function build()
	built = true
	local rocks = Instance.new("Folder")
	rocks.Name = "Rocas"
	LairRocks.build(rocks)
	LairNest.build(rocks)
	LairFalls.build(falls)
	LairCrystals.build(still)
	LairGeysers.build(still)
	LairLift.track(rocks, root)
	LairGeysers.start(function(): boolean
		return arrived
	end)
end

-- La lava ya arriba: el resto de la guarida.
local function settle(mine: number, instant: boolean)
	if mine ~= generation then
		return
	end
	arrived = true
	still.Parent = root
	LairAir.show()
	LairGround.ash(instant)
	LairParts.playPulses(true)
end

function LavaLair.arrive(instant: boolean)
	generation += 1
	if not built then
		build()
	end
	root.Parent = Workspace
	falls.Parent = root
	if instant then
		LairLift.snap(1)
		settle(generation, true)
		return
	end
	LairLift.go(1, EMERGE_SECONDS, EMERGE_DELAY)
	task.delay(RISE_SECONDS, settle, generation, false)
end

function LavaLair.level(y: number)
	if built then
		LairLift.level(y)
	end
end

function LavaLair.leave(instant: boolean)
	generation += 1
	arrived = false
	LairGround.restore()
	if not built then
		return
	end
	LairAir.hide()
	LairParts.playPulses(false)
	falls.Parent = nil
	still.Parent = nil
	if instant then
		LairLift.snap(0)
		return
	end
	LairLift.rumble(0.35)
	LairLift.go(0, SUBMERGE_SECONDS, 0)
end

return table.freeze(LavaLair)
