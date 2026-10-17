--!strict
--[[
	CraterMode

	Qué hay hoy en el cráter, en este cliente (lo decide CraterDrain):
		"water"  el lago (Orca y los demás)
		"lava"   el lago de lava del dragón (CraterLava)
		"sand"   el desierto del minotauro (CraterSand)
		"empty"  vacío: descanso y ruleta
	Lo leen quienes cambian según el relleno (ZoneMood, SkyCycle, AbyssRescue,
	SeaLife, DesertAir...). sandBlend() sube de 0 a 1 en FADE_SECONDS al llegar
	el desierto y baja igual al irse (para mezclar la luz cálida sin saltos).
]]

export type Mode = "water" | "empty" | "lava" | "sand"

local FADE_SECONDS = 3

local CraterMode = {}

local mode: Mode = "water" -- así lo deja TerrainBuilder
local listeners: { (Mode) -> () } = {}
local blendFrom, blendAt = 0, -math.huge -- sandBlend al cambiar y cuándo cambió

function CraterMode.get(): Mode
	return mode
end

function CraterMode.isSand(): boolean
	return mode == "sand"
end

function CraterMode.sandBlend(): number
	local t = math.clamp((os.clock() - blendAt) / FADE_SECONDS, 0, 1)
	local target = if mode == "sand" then 1 else 0
	return blendFrom + (target - blendFrom) * t
end

function CraterMode.set(value: Mode)
	if value == mode then
		return
	end
	blendFrom, blendAt = CraterMode.sandBlend(), os.clock()
	mode = value
	for _, listener in listeners do
		task.spawn(listener, value)
	end
end

-- listener(mode) en cada cambio (no se llama al conectarse: leer get()).
function CraterMode.onChanged(listener: (Mode) -> ())
	table.insert(listeners, listener)
end

return table.freeze(CraterMode)
