--!strict
--[[
	IceLair

	El hábitat de hielo del zorro de agua (GiantDef.ice): el cráter sigue lleno
	de agua (es el lago de siempre, CraterMode "ice") y encima va el hielo.
	Local de cada cliente, como el agua. CraterDrain avisa:
		arrive()  el agua ya está arriba: los témpanos (IceFloes) y las rocas
		          (IceRocks y las de la orilla, IceShore) suben del fondo y rompen
		          la superficie (IceLift); la orilla se escarcha de a poco (costra,
		          escarcha, nieve y cristales) y empieza el aire frío (IceAir).
		leave()   se va el zorro (descanso u otro monstruo): el aire frío se
		          apaga, la escarcha se derrite y los témpanos se hunden, antes de
		          que baje el agua o de que la guarida del descanso suba.
	Los lugares fijos (dónde se para, duerme o vigila el zorro) salen de
	Zorro/Guarida. Se arma todo la primera vez que llega el hielo.
	Con el hábitat completo de Blender (IceHabitat) la orilla (costra, escarcha,
	nieve, racimos y rocas de la repisa) y sus luces ya vienen en las mallas del
	servidor: no se arman, y la banquisa de la malla sube y baja con los témpanos
	(IceLift.float). Si el hábitat llega tarde (streaming) o se va, el lago se
	rearma con lo que corresponde (las mismas formas: salen de seeds).
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local IceAir = require(script.Parent.IceAir)
local IceFloes = require(script.Parent.IceFloes)
local IceHabitat = require(script.Parent.IceHabitat)
local IceLift = require(script.Parent.IceLift)
local IceRocks = require(script.Parent.IceRocks)
local IceShore = require(script.Parent.IceShore)

local EMERGE_SECONDS = 4 -- lo que tardan los témpanos en subir del fondo
local SINK_SECONDS = 1.1 -- se hunden antes de que el agua baje de más
local FROST_SECONDS = 3 -- la orilla se escarcha (o se derrite) en este tiempo
local FROST_DELAY = 1.5 -- la escarcha empieza cuando los témpanos ya vienen subiendo

local IceLair = {}

local root = Instance.new("Folder")
root.Name = "GuaridaDeHielo"
local shore = Instance.new("Folder") -- lo que no flota: se escarcha y se derrite
shore.Name = "Orilla"

local built = false
local complete = false -- se armó para el hábitat completo (sin orilla de primitivas)
local active = false -- el hielo está (entre arrive y leave)
local lake: Folder? = nil
local frost: { BasePart } = {}
local clear: { number } = {} -- la transparencia de cada pieza de la orilla, escarchada
local frostAmount = 0 -- 0 derretida, 1 escarchada
local fading: RBXScriptConnection? = nil

local function build(withHabitat: boolean)
	if lake then
		lake:Destroy()
	end
	shore:ClearAllChildren()
	table.clear(frost)
	table.clear(clear)
	built, complete = true, withHabitat
	local floating = Instance.new("Folder")
	floating.Name = "Lago"
	IceShore.build(floating, shore, withHabitat)
	IceRocks.build(floating)
	IceFloes.build(floating, IceShore.rocks(withHabitat), withHabitat)
	IceLift.track(floating, root)
	lake = floating
	for _, d in shore:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(frost, d)
			table.insert(clear, d.Transparency)
		end
	end
end

local function showFrost(amount: number)
	frostAmount = amount
	shore.Parent = if amount > 0 and not complete then root else nil
	if amount <= 0 then
		return
	end
	for i, part in frost do
		part.Transparency = 1 - (1 - clear[i]) * amount
	end
end

-- La orilla va de a poco hacia `target` (después de `delay`); de una si instant.
local function frostTo(target: number, delay: number, instant: boolean)
	if fading then
		fading:Disconnect()
		fading = nil
	end
	if instant then
		showFrost(target)
		return
	end
	local start, startAt = frostAmount, os.clock() + delay
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		local t = math.clamp((os.clock() - startAt) / FROST_SECONDS, 0, 1)
		if os.clock() >= startAt then
			showFrost(start + (target - start) * t)
		end
		if t >= 1 then
			connection:Disconnect()
			if fading == connection then
				fading = nil
			end
		end
	end)
	fading = connection
end

-- El hábitat completo apareció o se fue: su banquisa a IceLift y, si el hielo ya
-- está y se había armado para el otro caso, el lago de nuevo.
local function onHabitat()
	local model = IceHabitat.model()
	IceLift.float(if model then IceHabitat.floating(model) else {})
	if active and (model ~= nil) ~= complete then
		build(model ~= nil)
		showFrost(frostAmount)
		IceAir.show(complete)
	end
end

function IceLair.arrive(instant: boolean)
	active = true
	local withHabitat = IceHabitat.model() ~= nil
	if not built or withHabitat ~= complete then
		build(withHabitat)
	end
	root.Parent = Workspace
	IceAir.show(complete)
	if instant then
		IceLift.snap(1)
		frostTo(1, 0, true)
		return
	end
	IceLift.go(1, EMERGE_SECONDS, 0)
	frostTo(1, FROST_DELAY, false)
end

function IceLair.leave(instant: boolean)
	active = false
	IceAir.hide()
	if not built then
		return
	end
	frostTo(0, 0, instant)
	if instant then
		IceLift.snap(0)
		return
	end
	IceLift.go(0, SINK_SECONDS, 0)
end

IceHabitat.watch(onHabitat)

return table.freeze(IceLair)
