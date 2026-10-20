--!strict
--[[
	TerrainVersion

	La versión del terreno: SHAPE_VERSION más una huella de WorldLayout (todas sus
	claves, ordenadas). TerrainBuilder la anota en Workspace.Terrain (atributo
	TerrenoVersion) y, si el terreno guardado en el lugar ya tiene la de ahora, no lo
	vuelve a construir al arrancar el servidor.
		get() -> string

	SHAPE_VERSION se sube a mano al cambiar cómo se arma el terreno sin tocar
	WorldLayoutData (IslandShape, CraterShape, GardenShape, TerrainBuilder): el servidor
	no puede leer el código de los módulos para darse cuenta solo. Si se olvida, el
	terreno guardado queda viejo hasta que se regenere (docs/setup.md).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local SHAPE_VERSION = 1
local HASH_MODULO = 2 ^ 32

-- Texto estable de un valor: las tablas con sus claves ordenadas.
local function serialize(value: any): string
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys = {}
	for key in value do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	local parts = {}
	for _, key in keys do
		table.insert(parts, `{key}={serialize(value[key])}`)
	end
	return "{" .. table.concat(parts, ";") .. "}"
end

-- djb2: cada paso cabe de sobra en los 53 bits exactos de un número de Luau.
local function hash(text: string): number
	local result = 5381
	for index = 1, #text do
		result = (result * 33 + string.byte(text, index)) % HASH_MODULO
	end
	return result
end

local TerrainVersion = {}

function TerrainVersion.get(): string
	return `{SHAPE_VERSION}-{string.format("%08x", hash(serialize(WorldLayout)))}`
end

return table.freeze(TerrainVersion)
