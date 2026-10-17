--!strict
--[[
	Dragon/Aleteo

	Cuándo suena un aletazo y con qué fuerza, mirando el ala de verdad: en
	cada vuelta de la fase del aleteo (state.phase, en la bajada) mide cuánto
	recorrió la punta del ala izquierda respecto del pecho (con la animación,
	TransformedWorldCFrame) y lo compara con el largo del dragón. Un aletazo
	completo recorre ~1 largo; planeando o posado con las alas quietas, casi
	nada: así no suena cuando no aletea, sin depender de cómo se anime.
]]

local Tipos = require(script.Parent.Tipos)

export type Aleteo = { last: Vector3?, path: number, stroke: number? }

local QUIET = 0.25 -- recorrido (en largos) por debajo del cual no suena
local FULL = 1 -- y desde el cual suena entero

local Aleteo = {}

function Aleteo.new(): Aleteo
	return { last = nil, path = 0, stroke = nil }
end

-- Fuerza 0..1 del aletazo que acaba de terminar, o nil si sigue en la misma vuelta.
function Aleteo.step(a: Aleteo, rig: any, state: Tipos.State): number?
	local tip = rig.bones.AlaIzq3 or rig.bones.AlaIzq2
	local chest = rig.bones.Pecho or rig.root
	if not tip or not chest then
		return nil
	end
	local rel = tip.TransformedWorldCFrame.Position - chest.TransformedWorldCFrame.Position
	if a.last then
		a.path += (rel - a.last :: Vector3).Magnitude
	end
	a.last = rel
	local stroke = math.floor((state.phase + math.pi / 2) / (2 * math.pi))
	if a.stroke == nil then
		a.stroke = stroke -- recién enlazado: la primera vuelta no cuenta
	end
	if stroke == a.stroke then
		return nil
	end
	a.stroke = stroke
	local swing = a.path / math.max(state.length, 1)
	a.path = 0
	return math.clamp((swing - QUIET) / (FULL - QUIET), 0, 1)
end

return table.freeze(Aleteo)
