--!strict
--[[
	OrcaMotion/Rig

	Anima los huesos de la orca con Bone.Transform, sin AnimationController.
	Sirve para los dos árboles y elige por los huesos que encuentra:
		v2 (rig_orca_v2.py, las 4 etapas de bloques):
			Raiz > Pecho > Cabeza > Mandibula        (Boca, Espiraculo, Ojo{l}Mira: puntos)
			Pecho > Aleta{l} > Aleta{l}2             pectorales con codo
			Pecho > Cola1 > ... > Cola5 > AletaColaIzq, AletaColaDer
			Cola1 > Dorsal
		  Nado de cetáceo en Columna (onda, paleta, giros) y lo que cuelga en
		  Aletas; todo limitado contra Limites.
		viejo (rig_orca.py, la Orca fantasma): Raiz > Cola1..Cola4 y Raiz >
		  Dorsal. Se mueve igual que siempre (Fantasma).
	Al enlazar se miden los ejes del modelo (frente -Z, arriba Y) en el espacio
	de cada hueso y, en el v2, dónde cae cada junta a lo largo del cuerpo.
	Capas (guía, sección 7): base (respirar y soplar), locomoción (la onda),
	acción (truco y comer: arch, tail, bend, flukes, fin, head, jaw) y
	secundaria (resortes). Cada capa salta los huesos que el modelo no tiene.
]]

local Aletas = require(script.Aletas)
local Columna = require(script.Columna)
local Fantasma = require(script.Fantasma)
local Tipos = require(script.Tipos)

export type Axes = Tipos.Axes
export type Rig = Tipos.Rig
export type Pose = Tipos.Pose

-- Dónde cae cada junta (0 = nariz, 1 = punta de la cola) si no se puede medir
-- (proporciones de la adulta v2: cabeza 23 % del largo).
local DEFAULT_AT = table.freeze({
	Pecho = 0.3,
	Cola1 = 0.43,
	Cola2 = 0.55,
	Cola3 = 0.66,
	Cola4 = 0.75,
	Cola5 = 0.83,
	AletaCola = 0.89,
})
local SPINE = { "Pecho", "Cola1", "Cola2", "Cola3", "Cola4", "Cola5", "AletaCola" }
local BACK = { "Cola1", "Cola2", "Cola3", "Cola4", "Cola5", "AletaColaIzq", "AletaColaDer" }
local FINS = { "AletaIzq", "AletaIzq2", "AletaDer", "AletaDer2" }

local Rig = {}

-- Mide las juntas a lo largo del eje Pecho → Cola5: de la nariz (Boca) a la punta.
local function measure(bones: { [string]: Bone }): { [string]: number }
	local chest, last, fluke = bones.Pecho, bones.Cola5, bones.AletaColaIzq or bones.AletaColaDer
	local nose = bones.Boca or bones.Cabeza
	if not (chest and last and fluke and nose) then
		return table.clone(DEFAULT_AT)
	end
	local axis = last.WorldPosition - chest.WorldPosition
	if axis.Magnitude < 1e-3 then
		return table.clone(DEFAULT_AT)
	end
	axis = axis.Unit
	local function along(bone: Bone): number
		return (bone.WorldPosition - nose.WorldPosition):Dot(axis)
	end
	local flukeAt = along(fluke)
	local length = flukeAt + (flukeAt - along(last)) -- el lóbulo sigue más o menos otro tramo
	local at: { [string]: number } = { AletaCola = flukeAt / math.max(length, 1e-3) }
	local before = 0
	for _, name in SPINE do
		local bone = bones[name]
		local s = if name == "AletaCola"
			then at.AletaCola
			elseif bone then along(bone) / length
			else -1
		if s <= before or s >= 1 then -- falta un hueso o no van en orden: mejor las proporciones
			return table.clone(DEFAULT_AT)
		end
		at[name], before = s, s
	end
	return at
end

function Rig.bind(model: Model): Rig?
	local bones: { [string]: Bone } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Bone") then
			bones[descendant.Name] = descendant
		end
	end
	local root = bones.Raiz
	if not root then
		return nil
	end
	local pivot = model:GetPivot()
	local axes: { [string]: Tipos.Axes } = {}
	for name, bone in bones do
		-- WorldCFrame no incluye Transform: es la pose de reposo.
		local rest = (pivot:Inverse() * bone.WorldCFrame).Rotation
		axes[name] = {
			pitch = rest:VectorToObjectSpace(Vector3.xAxis),
			yaw = rest:VectorToObjectSpace(Vector3.yAxis),
			roll = rest:VectorToObjectSpace(Vector3.zAxis),
			side = math.sign(pivot:PointToObjectSpace(bone.WorldPosition).X),
		}
	end
	local size = model:GetExtentsSize().Y
	local center = pivot:PointToObjectSpace(root.WorldPosition).Y / math.max(size, 0.01)
	-- v2: la cola tiene 5 tramos o cuelga del Pecho (en el viejo cuelga de la Raiz).
	local cola1: Bone?, chest: Bone? = bones.Cola1, bones.Pecho
	local v2 = if bones.Cola5 then true elseif cola1 and chest then cola1.Parent == chest else false
	local back, rollSign = {}, {}
	for _, name in BACK do
		back[name] = true
	end
	for _, name in FINS do
		local a = axes[name]
		rollSign[name] = if a then -a.side else 1
	end
	return {
		bones = bones,
		axes = axes,
		center = math.clamp(center, 0.2, 0.7),
		springs = {},
		v2 = v2,
		at = if v2 then measure(bones) else {},
		back = back,
		rollSign = rollSign,
		written = {},
		chain = { pitch = table.create(5, 0), yaw = table.create(5, 0) },
	}
end

function Rig.apply(rig: Rig, pose: Pose, dt: number)
	if rig.v2 then
		Aletas(rig, pose, dt, Columna(rig, pose, dt))
	else
		Fantasma(rig, pose, dt)
	end
end

-- Posición actual (con la animación) de un hueso; nil si el modelo no lo tiene.
function Rig.point(rig: Rig?, name: string): Vector3?
	local bone = rig and rig.bones[name]
	return if bone then bone.TransformedWorldCFrame.Position else nil
end

return table.freeze(Rig)
