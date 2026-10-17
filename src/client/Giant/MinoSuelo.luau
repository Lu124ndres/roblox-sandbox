--!strict
--[[
	MinoSuelo

	Sobre qué está parado el minotauro, para que MinoStand elija sonidos y
	efectos:
		place(inner)          etapa (por el nombre del modelo: …E1 … E4 o
		                      …E1_v2) y si su hábitat es arena: def.sand del
		                      gigante en Config.Giants.chain, buscado por el id
		                      (el Model del gigante se llama como def.id), como
		                      CraterDrain busca lava.
		ground(motion, place) el punto del suelo bajo sus pies: sobre arena, un
		                      rayo hacia abajo (sin agua ni el propio gigante);
		                      con agua, la superficie del agua (motion.water).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Minotauro = require(ReplicatedStorage.Shared.Minotauro)

local RAY_ABOVE = 0.5 -- el rayo sale a media altura del gigante...
local RAY_EXTRA = 400 -- ...y baja su alto más esto

export type Place = { stage: number, sand: boolean, model: Instance? }

local MinoSuelo = {}

local defs: { [string]: Config.GiantDef } = {}
for _, def in Config.Giants.chain do
	defs[def.id] = def
end

-- El gigante por el Model que lo contiene o, si todavía no tiene padre, por el
-- nombre base del modelo de la etapa (el más largo que calce: Orca y OrcaFantasma).
local function defFor(inner: Model): Config.GiantDef?
	local parent = inner.Parent
	local byId = if parent then defs[parent.Name] else nil
	if byId then
		return byId
	end
	local best: Config.GiantDef? = nil
	for _, def in Config.Giants.chain do
		local base = def.modelBase
		if string.sub(inner.Name, 1, #base) == base and (not best or #base > #best.modelBase) then
			best = def
		end
	end
	return best
end

function MinoSuelo.place(inner: Model?): Place
	if not inner then
		return { stage = 1, sand = false, model = nil }
	end
	local digit = string.match(inner.Name, "E(%d)_v%d+$") or string.match(inner.Name, "E(%d)$")
	local def = defFor(inner)
	return {
		stage = math.clamp(tonumber(digit) or 1, 1, 4),
		sand = def ~= nil and def.sand == true,
		model = inner.Parent or inner,
	}
end

function MinoSuelo.ground(motion: Minotauro.Motion, place: Place): Vector3
	local water = motion.water()
	if not place.sand then
		return water
	end
	local height = motion.state.height
	local center = motion.state.center
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip: { Instance } = {}
	if place.model then
		table.insert(skip, place.model)
	end
	params.FilterDescendantsInstances = skip
	params.IgnoreWater = true
	local origin = center + Vector3.new(0, height * RAY_ABOVE, 0)
	local hit = Workspace:Raycast(origin, Vector3.new(0, -(height + RAY_EXTRA), 0), params)
	return if hit then hit.Position else Vector3.new(center.X, water.Y, center.Z)
end

return table.freeze(MinoSuelo)
