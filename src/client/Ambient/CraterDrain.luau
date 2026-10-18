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
		  el que salió: agua, lava (GiantDef.lava), arena (GiantDef.sand) o
		  agua con hielo (GiantDef.ice: con el agua arriba suben los témpanos,
		  IceLair), y recién entonces llega el monstruo. Entre agua y agua con
		  hielo el agua se queda: solo llega o se va el hielo.
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
local CraterGuard = require(script.Parent.CraterGuard)
local CraterSand = require(script.Parent.CraterSand)
local GuaridaSube = require(script.Parent.GuaridaSube)
local IceLair = require(script.Parent.IceLair)
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
		elseif def and def.ice then
			return "ice"
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
		local keepWater = CraterMode.isWet() and (from == "water" or from == "ice")
		if from == "ice" then
			IceLair.leave(instant or (swap and not keepWater)) -- con agua debajo se hunde sin apuro
		end
		if keepWater then
			if target == "ice" then
				IceLair.arrive(instant)
			end
			return
		end
		if from == "water" or from == "ice" then
			onShown(false)
			task.spawn(LakeFill.drain, instant or swap)
		elseif from == "lava" then
			CraterLava.sink(instant or swap)
		elseif from == "sand" then
			CraterSand.sink(instant or swap)
		end
		if target == "water" or target == "ice" then
			task.spawn(LakeFill.refill, function()
				onShown(true)
				if CraterMode.get() == "ice" then
					IceLair.arrive(false) -- con el agua arriba suben los témpanos
				end
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
	CraterGuard.start() -- con streaming, el agua del servidor puede volver encima
end

return CraterDrain
