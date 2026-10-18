--!strict
--[[
	Zorro/Pose/Tronco

	La cuenta de Pose.apply sin tocar huesos: de la pose a los giros de Cadera,
	Columna y Pecho (cabeceo, giro, alabeo) y a lo que las claves del cuerpo piden a
	la cabeza, la mandíbula y las orejas. tools/blender/zorro_v2_poses_cuerpo.py
	repite esta cuenta para medir las poses.
		sentado    la cadera baja y el pecho se levanta (SIT); el cuello endereza la
		           cabeza (HEAD_LEVEL)
		enroscado  el lomo se curva hacia curlSide y la cabeza gira hacia la cola y baja
		rascarse   la cabeza gira, cabecea y se ladea hacia la pata; la cadera se apoya
		           del otro lado
		lamerse    la cabeza busca la pata; sentado, el pecho se encorva hacia ella
		estirarse  el lomo se hunde y el pecho sube
		columna    el cuerpo se curva de lado (spine) y la cabeza lo sigue hacia la cola
		caminar    la cadera cae del lado de la trasera que se levanta, el pecho del de
		           la delantera, el lomo se tuerce con las traseras y la cabeza cabecea
		           con cada mano que pisa
		picada     el pecho baja (en picada), la cabeza mira abajo, las orejas adelante
]]

local Ajustes = require(script.Parent.Parent.Patas.Ajustes)
local Plano = require(script.Parent.Parent.Patas.Plano)

export type Giro = { number } -- cabeceo, giro, alabeo
export type Tronco = {
	cadera: Giro,
	columna: Giro,
	pecho: Giro,
	yaw: number, -- objetivo de la mirada (con lookYaw)
	pitch: number, -- objetivo del cabeceo (con lookPitch)
	tilt: number,
	jaw: number, -- se suma a jaw
	ears: number, -- se suma a earL y earR
	quiver: number, -- el temblor de la sacudida
	legs: { [string]: Plano.Leg },
}

local Tronco = {}

function Tronco.compute(
	p: { [string]: number },
	A: Ajustes.Etapa,
	stride: number,
	now: number
): Tronco
	local function v(key: string): number
		return p[key] or 0
	end
	local function u01(key: string): number
		return math.clamp(v(key), 0, 1)
	end
	local quiver = math.sin(now * 38) * 0.22 * v("shake")
	local lean, breathe, crouch, sway = v("lean"), v("breathe"), v("crouch"), v("sway")
	local bow = math.min(v("bow"), A.bowMax)
	local sit, stretch, pounce, walk = u01("sit"), u01("stretch"), u01("pounce"), u01("walk")
	local curl, scratch = u01("curl"), u01("scratch")
	local pawCap = 1 + (A.pawSitMax - 1) * sit -- sentado, el antebrazo topa con el pecho
	local pl, pr = math.min(u01("pawL"), pawCap), math.min(u01("pawR"), pawCap)
	local paw = math.max(pl, pr)
	local cside = if v("curlSide") >= 0 then 1 else -1
	local sside = if v("scratchSide") >= 0 then 1 else -1
	local legs = Plano.cycle(p, stride)

	local lateral = math.clamp(v("spine"), -1, 1) + cside * Ajustes.CURL_SPINE * curl
	local yawSpine = math.clamp(lateral * Ajustes.SPINE_MAX, -Ajustes.SPINE_MAX, Ajustes.SPINE_MAX)
	local rollHip = 0.06 * (legs.HDer.lift - legs.HIzq.lift)
	local rollChest = 0.05 * (legs.FDer.lift - legs.FIzq.lift)
	local yawStep = 0.04 * (legs.HIzq.forward - legs.HDer.forward) / math.max(stride, 1e-6)
	local S, St = Ajustes.SIT, Ajustes.STRETCH_TRUNK
	local hunch = A.pawHunch * sit * paw
	local hip = -bow * 0.2 + crouch * 0.05 + sit * S[1] + stretch * St[1] - pounce * 0.35
	local spine = lean * 0.4
		+ breathe
		- bow * 0.25
		+ sit * S[2]
		+ stretch * St[2]
		- pounce * 0.1
		- walk * 0.03
		- hunch * 0.4
	local chest = lean * 0.4
		+ breathe * 0.7
		- bow * 0.2
		+ sit * S[3]
		+ stretch * St[3]
		- hunch * 0.6
	local level = Ajustes.HEAD_LEVEL * (sit * (S[1] + S[2] + S[3]) - hunch + stretch * 0.06)

	-- La cabeza: lo que pide cada clave, encima de la mirada.
	local k = math.min(sit, 1)
	local ph = A.pawHeadStand
	local phYaw = ph[1] + (A.pawHeadSit[1] - ph[1]) * k
	local phPitch = ph[2] + (A.pawHeadSit[2] - ph[2]) * k
	local nod = 0.04 * walk * math.cos(2 * v("walkPhase") - math.pi) -- cabecea con cada mano
	local sh = A.scratchHead
	local yaw = v("lookYaw")
		+ cside * curl * A.curlHead[1]
		+ sside * scratch * sh[1]
		+ (pl - pr) * phYaw
		- yawSpine * 0.5 * (1 - curl)
	local pitch = v("lookPitch")
		+ bow * 0.5
		- level
		+ curl * A.curlHead[2]
		+ scratch * sh[2]
		+ paw * phPitch
		- pounce * 0.35
		- 0.05 * walk
		- nod
	return {
		cadera = {
			hip,
			-yawSpine * 0.3 + yawStep,
			sway + quiver + rollHip + sside * scratch * 0.04,
		},
		columna = { spine, yawSpine - yawStep, -sway * 0.4 - quiver * 0.8 - rollHip * 0.6 },
		pecho = {
			chest,
			math.clamp(yawSpine + v("lookYaw") * 0.1, -Ajustes.SPINE_MAX, Ajustes.SPINE_MAX),
			quiver * 0.6 + rollChest,
		},
		yaw = yaw,
		pitch = pitch,
		tilt = v("tilt") - sside * scratch * (sh[3] + 0.06 * v("scratchBeat")),
		jaw = 0.15 * paw,
		ears = -0.4 * curl + 0.6 * pounce,
		quiver = quiver,
		legs = legs,
	}
end

return table.freeze(Tronco)
