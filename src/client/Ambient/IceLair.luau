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
	Zorro/Guarida. Se arma todo una sola vez, la primera vez que llega el hielo.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local IceAir = require(script.Parent.IceAir)
local IceFloes = require(script.Parent.IceFloes)
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
local frost: { BasePart } = {}
local clear: { number } = {} -- la transparencia de cada pieza de la orilla, escarchada
local frostAmount = 0 -- 0 derretida, 1 escarchada
local fading: RBXScriptConnection? = nil

local function build()
	built = true
	local lake = Instance.new("Folder")
	lake.Name = "Lago"
	IceShore.build(lake, shore)
	IceRocks.build(lake)
	IceFloes.build(lake, IceShore.rocks())
	IceLift.track(lake, root)
	for _, d in shore:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(frost, d)
			table.insert(clear, d.Transparency)
		end
	end
end

local function showFrost(amount: number)
	frostAmount = amount
	shore.Parent = if amount > 0 then root else nil
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

function IceLair.arrive(instant: boolean)
	if not built then
		build()
	end
	root.Parent = Workspace
	IceAir.show()
	if instant then
		IceLift.snap(1)
		frostTo(1, 0, true)
		return
	end
	IceLift.go(1, EMERGE_SECONDS, 0)
	frostTo(1, FROST_DELAY, false)
end

function IceLair.leave(instant: boolean)
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

return table.freeze(IceLair)
