--!strict
--[[
	CraterDrain

	Decide qué llena el volcán en este cliente, según EstadoGigante.VolcanVacio
	(lo publica RestArena) y el monstruo:
		- al empezar el descanso se va lo que haya (el agua baja, LakeFill; la
		  lava se hunde, CraterLava; la arena se escurre, CraterSand) mientras
		  la guarida sube desde el fondo (GuaridaSube, que también la hunde al
		  terminar el descanso);
		- vacío también en la ruleta; después (VolcanLlenando) se llena según
		  el que salió: agua, lava (GiantDef.lava) o arena (GiantDef.sand), y
		  recién entonces llega el monstruo.
	Todo es de cada cliente (los personajes se simulan en su propio cliente).
	Quien entra lo ve como está, al instante. El modo queda en CraterMode;
	onShown avisa a CraterWater para esconder el abismo, las motas y las
	fumarolas cuando no hay agua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local CraterLava = require(script.Parent.CraterLava)
local CraterMode = require(script.Parent.CraterMode)
local CraterSand = require(script.Parent.CraterSand)
local GuaridaSube = require(script.Parent.GuaridaSube)
local LakeFill = require(script.Parent.LakeFill)
local SandProps = require(script.Parent.SandProps)

type Mode = CraterMode.Mode

local CraterDrain = {}

local defs: { [string]: Config.GiantDef } = {}
for _, def in Config.Giants.chain do
	defs[def.id] = def
end

-- onShown(false) cuando no hay agua (vacío, lava o arena): sin abismo ni efectos del agua.
function CraterDrain.start(onShown: (boolean) -> ())
	local stateFolder = ReplicatedStorage:WaitForChild(Protocol.GiantStateFolder)
	local ATTR = Protocol.GiantAttributes
	GuaridaSube.watch(stateFolder)
	SandProps.start()
	-- Vacío en el descanso y en la ruleta: se llena cuando llega el siguiente.
	local function wanted(): Mode
		local refilling = stateFolder:GetAttribute(ATTR.Refilling) == true
		if
			not refilling
			and (
				stateFolder:GetAttribute(ATTR.Drained) == true
				or stateFolder:GetAttribute(ATTR.Phase) == "rest"
			)
		then
			return "empty"
		end
		-- Al llenarse antes de que llegue, el relleno es el del que salió en la ruleta.
		local id = stateFolder:GetAttribute(if refilling then ATTR.RouletteResult else ATTR.Id)
		local def = defs[id :: any]
		if def and def.lava then
			return "lava"
		end
		return if def and def.sand then "sand" else "water"
	end
	local function apply(instant: boolean)
		local target: Mode = wanted()
		local from: Mode = CraterMode.get()
		if target == from then
			return
		end
		CraterMode.set(target)
		-- Lo que había se va; de una si enseguida viene otra cosa (no se mezclan).
		local swap = target ~= "empty"
		if from == "water" then
			onShown(false)
			task.spawn(LakeFill.drain, instant or swap)
		elseif from == "lava" then
			CraterLava.sink(instant or swap)
		elseif from == "sand" then
			CraterSand.sink(instant or swap)
		end
		if target == "water" then
			task.spawn(LakeFill.refill, function()
				onShown(true)
			end)
		elseif target == "lava" then
			CraterLava.rise(instant)
		elseif target == "sand" then
			CraterSand.rise(instant)
		end
	end
	for _, attribute in { ATTR.Drained, ATTR.Phase, ATTR.Id, ATTR.Refilling } do
		stateFolder:GetAttributeChangedSignal(attribute):Connect(function()
			apply(false)
		end)
	end
	apply(true) -- quien entra lo ve como está, al instante
end

return CraterDrain
