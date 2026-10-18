--!strict
--[[
	Zorro/Rutina/Probar

	Modo de prueba para revisar las conductas una por una en Play: si
	Workspace tiene el atributo ATTRIBUTE con el nombre de una conducta, la
	rutina la repite en bucle en el témpano del centro, de frente a la puerta,
	con r = R (sin pausas ni viajes). Sin el atributo, rutina normal.
		Workspace:SetAttribute("ZorroConducta", "rascarse")   -- empieza
		Workspace:SetAttribute("ZorroConducta", nil)          -- vuelve a la rutina
		find(lista)   la conducta pedida (o nil)
		at(now, etapa, conducta)  base, rumbo, u, la clave de la vuelta y r
]]

local Workspace = game:GetService("Workspace")

local Guarida = require(script.Parent.Parent.Guarida)
local Lugares = require(script.Parent.Lugares)
local Tipos = require(script.Parent.Parent.Tipos)

local ATTRIBUTE = "ZorroConducta"
local R = 0.37
local MIN_SECONDS, MAX_SECONDS = 0.5, 40

local Probar = {}

function Probar.find(lista: { Tipos.Conducta }): Tipos.Conducta?
	local name = Workspace:GetAttribute(ATTRIBUTE)
	if type(name) ~= "string" then
		return nil
	end
	for _, conducta in lista do
		if conducta.nombre == name then
			return conducta
		end
	end
	return nil
end

function Probar.at(
	now: number,
	etapa: number,
	conducta: Tipos.Conducta
): (Vector3, number, number, number, number)
	local spot = Guarida.find("Centro") or Guarida.spots[1]
	local point = Guarida.point(spot)
	local seconds = math.clamp(conducta.duracion(etapa, R), MIN_SECONDS, MAX_SECONDS)
	local loop = math.floor(now / seconds)
	local u = (now - loop * seconds) / seconds
	return point, Lugares.facing(point), u, -(loop + 1), R
end

return table.freeze(Probar)
