--!strict
--[[
	Zorro/Patas

	Las cuatro patas del zorro: el único que escribe Hombro, Brazo, Antebrazo, Mano,
	Muslo, Pierna, Tobillo y Pie (Izq y Der). Lee de la pose:
		stepFL/FR/HL/HR   levanta cada pata (0..1): delantera/trasera, Izq/Der
		bow               reverencia: dobla las de adelante
		crouch            se agacha con las cuatro (para saltar)
	(Las claves nuevas de la ola 3 están en docs/plan_zorro_v2.md, "Ola 3".)
]]

local Rig = require(script.Parent.Rig)

export type Pose = { [string]: number }

-- La reverencia dobla las delanteras (por bow): con menos, el pecho baja y las manos
-- se hunden en el agua (medido en tools/blender/zorro_v2_poses.py).
local BOW_BEND = 1.5

local Patas = {}

local function leg(
	rig: Rig.Rig,
	front: boolean,
	s: string,
	lift: number,
	bend: number,
	swing: number
)
	if front then
		Rig.turn(rig, `Hombro{s}`, swing * 0.4, 0, 0)
		Rig.turn(rig, `Brazo{s}`, 0.35 * lift + swing * 0.6 - bend * 0.5, 0, 0)
		Rig.turn(rig, `Antebrazo{s}`, -1.1 * lift + bend * 0.9, 0, 0)
		Rig.turn(rig, `Mano{s}`, -0.8 * lift - bend * 0.4, 0, 0)
	else
		Rig.turn(rig, `Muslo{s}`, 0.3 * lift + swing * 0.5 + bend * 0.5, 0, 0)
		Rig.turn(rig, `Pierna{s}`, -0.4 * lift - bend * 0.9, 0, 0)
		Rig.turn(rig, `Tobillo{s}`, 0.7 * lift + bend * 0.8, 0, 0)
		Rig.turn(rig, `Pie{s}`, -0.5 * lift - bend * 0.4, 0, 0)
	end
end

function Patas.apply(rig: Rig.Rig, p: Pose, _t: number, _dt: number)
	local function v(key: string): number
		return p[key] or 0
	end
	local bow, crouch = v("bow"), v("crouch")
	leg(rig, true, "Izq", v("stepFL"), bow * BOW_BEND + crouch, 0)
	leg(rig, true, "Der", v("stepFR"), bow * BOW_BEND + crouch, 0)
	leg(rig, false, "Izq", v("stepHL"), crouch - bow * 0.15, 0)
	leg(rig, false, "Der", v("stepHR"), crouch - bow * 0.15, 0)
end

return table.freeze(Patas)
