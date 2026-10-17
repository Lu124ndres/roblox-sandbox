--!strict
--[[
	EvolveLook

	Cómo se ve la evolución de cada gigante (EvolveFx): su color de acento
	(aura, energía, columna de luz, onda), un segundo color para el núcleo
	del estallido y qué hay bajo sus pies (agua, arena o lava), que cambia
	la salpicadura del suelo. También el instante del estallido: a los
	BURST_SECONDS del inicio de la evolución, que es cuando cambia el modelo
	(la rutina del minotauro explota hacia arriba en ese mismo momento).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)

export type Ground = "water" | "sand" | "lava"

export type Look = {
	accent: Color3, -- color propio del gigante
	core: Color3, -- centro del estallido y chispas
	gold: Color3, -- chispas que caen en la calma
	ground: Ground,
	dust: Color3, -- polvo o bruma del suelo
}

local BURST_SECONDS = 1.3 -- carga: 0..1.3 s; estallido; calma hasta evolveSeconds

local ACCENTS: { [string]: { accent: Color3, core: Color3 } } = {
	Orca = { accent = Color3.fromRGB(80, 200, 255), core = Color3.fromRGB(225, 248, 255) },
	Minotauro = { -- dorado con corazón de lava
		accent = Color3.fromRGB(255, 176, 40),
		core = Color3.fromRGB(255, 92, 24),
	},
	DragonMarino = { accent = Color3.fromRGB(70, 255, 160), core = Color3.fromRGB(255, 150, 60) },
	ZorroDeAgua = { accent = Color3.fromRGB(70, 225, 255), core = Color3.fromRGB(210, 255, 255) },
	OrcaFantasma = { accent = Color3.fromRGB(175, 110, 255), core = Color3.fromRGB(130, 255, 205) },
}
local FALLBACK = { accent = UIConfig.Colors.Coins, core = Color3.fromRGB(255, 255, 255) }

local DUST: { [Ground]: Color3 } = {
	water = Color3.fromRGB(235, 250, 255),
	sand = Color3.fromRGB(226, 196, 140),
	lava = Color3.fromRGB(90, 70, 64),
}

local EvolveLook = {}

-- Segundos desde el inicio de la evolución hasta el estallido (nunca después del final).
function EvolveLook.burstSeconds(): number
	return math.min(BURST_SECONDS, Config.Giants.cycle.evolveSeconds)
end

-- Segundos que faltan para el estallido de la evolución en curso (0 si no hay).
function EvolveLook.secondsToBurst(): number
	local state = ReplicatedStorage:FindFirstChild(Protocol.GiantStateFolder)
	local untilAt = state and state:GetAttribute(Protocol.GiantAttributes.EvolvingUntil)
	if type(untilAt) ~= "number" then
		return 0
	end
	local burstAt = untilAt - Config.Giants.cycle.evolveSeconds + EvolveLook.burstSeconds()
	return math.max(0, burstAt - Workspace:GetServerTimeNow())
end

function EvolveLook.forGiant(def: Config.GiantDef): Look
	local colors = ACCENTS[def.id] or FALLBACK
	local ground: Ground = if def.sand then "sand" elseif def.lava then "lava" else "water"
	return {
		accent = colors.accent,
		core = colors.core,
		gold = UIConfig.Colors.Coins,
		ground = ground,
		dust = DUST[ground],
	}
end

return table.freeze(EvolveLook)
