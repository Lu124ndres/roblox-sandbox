--!strict
--[[
	Zorro/Patas

	Las cuatro patas del zorro: el único que escribe Hombro, Brazo, Antebrazo, Mano,
	Muslo, Pierna, Tobillo y Pie (Izq y Der). Cada pata busca su pie en el piso con IK
	en el plano del cuerpo (Patas/Plano): el piso está a Pose.drop de la base (lo que
	bajó al sentarse, echarse, agacharse...), así los pies apoyados no se hunden ni
	flotan aunque el tronco se incline. La delantera dobla el codo hacia atrás (IK en
	Brazo y Antebrazo, el omóplato acompaña el paso); la trasera pone el muslo según lo
	plegada que esté (adelante al sentarse) y dobla el talón hacia atrás (IK en Pierna y
	Tobillo). Encima, mezclado por su clave: lamerse (pawL/pawR), rascarse (scratch, la
	trasera de scratchSide) y la picada (pounce), con ángulos medidos (Patas/Ajustes).
	Lee de la pose: stepFL/FR/HL/HR (levanta la pata), bow, crouch (por el piso), sit,
	lie, stretch, walk y walkPhase (el paso, Plano.cycle), pawL/pawR, scratch,
	scratchSide, scratchBeat y pounce.
]]

local Ajustes = require(script.Ajustes)
local Plano = require(script.Plano)
local Rig = require(script.Parent.Rig)

export type Pose = { [string]: number }
-- Lo que Pose.apply ya decidió: cabeceo local de Cadera, Columna y Pecho, cuánto bajó la
-- base (Pose.drop) y el paso de cada pata (Plano.cycle).
export type Trunk = {
	hip: number,
	spine: number,
	chest: number,
	drop: number,
	legs: { [string]: Plano.Leg },
	etapa: Ajustes.Etapa,
}

local rotate, angle, wrap = Plano.rotate, Plano.angle, Plano.wrap

local Patas = {}

local function u01(p: Pose, key: string): number
	return math.clamp(p[key] or 0, 0, 1)
end

-- Escribe los cuatro huesos de una pata (cabeceo y alabeo).
local function write(rig: Rig.Rig, names: { string }, pitch: { number }, roll: { number })
	for i, name in names do
		Rig.turn(rig, name, pitch[i], 0, roll[i])
	end
end

local function front(
	rig: Rig.Rig,
	geo: Plano.Geometry,
	p: Pose,
	tr: Trunk,
	s: string,
	side: number,
	l: string
)
	local A = tr.etapa
	local ho, br, an, ma = geo[`Hombro{s}`], geo[`Brazo{s}`], geo[`Antebrazo{s}`], geo[`Mano{s}`]
	local l1, l2 = (an - br).Magnitude, (ma - an).Magnitude
	local length = l1 + l2
	local leg = tr.legs[`F{s}`]
	local lift = math.clamp((p[`stepF{l}`] or 0) + leg.lift * A.walkLift[1], 0, 1.5)
	local sit, lie = u01(p, "sit"), u01(p, "lie")
	local bow = math.min(p.bow or 0, A.bowMax)
	local chestSum = tr.hip + tr.spine + tr.chest
	local shoulder = 0.6 * leg.forward / length + Ajustes.SIT_SHOULDER * sit * chestSum
	local cadera, columna, pecho = geo.Cadera, geo.Columna, geo.Pecho
	-- La articulación del brazo, llevada por el omóplato, el pecho, la columna y la cadera.
	local a = rotate(
		rotate(rotate(rotate(br, ho, shoulder), pecho, tr.chest), columna, tr.spine),
		cadera,
		tr.hip
	)
	local still = ma.X
	local vertical = a.X + (ma.X - br.X) + A.sitFront * length
	local ahead = a.X + A.lieReach * length
	local f = still
		+ sit * (vertical - still)
		+ lie * (ahead - still)
		+ leg.forward
		+ bow * A.bowReach * length
	local target = Vector2.new(f, tr.drop + ma.Y + Ajustes.LIFT_U * length * lift)
	local a1, a2 = Plano.twoBone(a, target, l1, l2, -1)
	local c1, c2 = wrap(a1 - angle(an - br)), wrap(a2 - angle(ma - an))
	local c3 = (Ajustes.LIE_WRIST * lie + A.bowWrist * bow) * c2 -- la mano, plana en el piso
	local pitch =
		{ shoulder, c1 - chestSum - shoulder, c2 - c1, c3 - c2 + Ajustes.LIFT_CURL * lift }
	local roll = { 0, 0, 0, 0 }
	local paw = math.min(u01(p, `paw{l}`), 1 + (A.pawSitMax - 1) * sit)
	if paw > 0 then -- lamerse: la mano sube al hocico
		local k = math.min(sit, 1)
		for i = 1, 4 do
			local fk = A.pawStand[i] + (A.pawSit[i] - A.pawStand[i]) * k
			pitch[i] += (fk - pitch[i]) * paw
		end
		roll[2] = -side * (A.pawStand[5] + (A.pawSit[5] - A.pawStand[5]) * k) * paw
	end
	local pounce = u01(p, "pounce")
	if pounce > 0 then -- en el aire: las manos juntas, hacia abajo
		for i = 1, 4 do
			pitch[i] += (Ajustes.POUNCE_F[i] - pitch[i]) * pounce
			roll[i] -= side * Ajustes.POUNCE_IN * pounce
		end
	end
	write(rig, { `Hombro{s}`, `Brazo{s}`, `Antebrazo{s}`, `Mano{s}` }, pitch, roll)
end

local function hind(
	rig: Rig.Rig,
	geo: Plano.Geometry,
	p: Pose,
	tr: Trunk,
	s: string,
	side: number,
	l: string
)
	local A = tr.etapa
	local mu, pi, to, pie = geo[`Muslo{s}`], geo[`Pierna{s}`], geo[`Tobillo{s}`], geo[`Pie{s}`]
	local l1, l2, l3 = (pi - mu).Magnitude, (to - pi).Magnitude, (pie - to).Magnitude
	local total = l1 + l2 + l3
	local leg = tr.legs[`H{s}`]
	local lift = math.clamp((p[`stepH{l}`] or 0) + leg.lift * A.walkLift[2], 0, 1.5)
	local sit, lie, stretch = u01(p, "sit"), u01(p, "lie"), u01(p, "stretch")
	local hip = rotate(mu, geo.Cadera, tr.hip)
	local f = pie.X
		+ (sit * A.sitPaw + lie * A.liePaw - stretch * Ajustes.STRETCH_BACK) * total
		+ leg.forward
	local ground = Vector2.new(f, tr.drop + pie.Y)
	local target = ground + Vector2.new(0, Ajustes.LIFT_UH * total * lift)
	local rest = (pie - mu).Magnitude
	local beta0 = wrap(angle(pi - mu) - angle(pie - mu))
	local d = target - hip
	local reach = math.max(d.Magnitude, 1e-9)
	-- Lo plegada sale del pie en el suelo: levantar la pata no la pliega bajo la grupa.
	local folded = math.clamp((rest - (ground - hip).Magnitude) / (Ajustes.FOLD_RANGE * rest), 0, 1)
	local beta = beta0
		+ (Ajustes.FOLD_BETA - beta0) * folded ^ A.foldPow
		- stretch * Ajustes.STRETCH_BETA
	local cmin = (l1 * l1 + reach * reach - (l2 + l3) ^ 2 * 0.998) / (2 * l1 * reach)
	if cmin > -1 then -- el muslo no se abre más de lo que deja llegar al pie
		local bmax = if cmin < 1 then math.acos(cmin) else 0
		beta = math.clamp(beta, -bmax, bmax)
	end
	local a1 = angle(d) + beta
	local knee = hip + Vector2.new(math.cos(a1), math.sin(a1)) * l1
	local a2, a3 = Plano.twoBone(knee, target, l2, l3, -1)
	local c1, c2, c3 =
		wrap(a1 - angle(pi - mu)), wrap(a2 - angle(to - pi)), wrap(a3 - angle(pie - to))
	local pitch = { c1 - tr.hip, c2 - c1, c3 - c2, -c3 + Ajustes.LIFT_CURL_H * lift }
	local roll = { 0, 0, 0, 0 }
	local scratchSide = if (p.scratchSide or 1) >= 0 then 1 else -1
	local scratch = if scratchSide == side then u01(p, "scratch") else 0
	if scratch > 0 then -- rascarse: la pata sube por fuera hacia la cabeza y late
		local L, beat = A.scratchLeg, p.scratchBeat or 0
		local fk = {
			L[1],
			L[3] + Ajustes.SCRATCH_BEAT[1] * beat,
			L[4] + Ajustes.SCRATCH_BEAT[2] * beat,
			L[5],
		}
		for i = 1, 4 do
			pitch[i] += (fk[i] - pitch[i]) * scratch
		end
		roll[1] += side * L[2] * scratch
	end
	local pounce = u01(p, "pounce")
	if pounce > 0 then -- en el aire: estiradas hacia atrás
		for i = 1, 4 do
			pitch[i] += (Ajustes.POUNCE_H[i] - pitch[i]) * pounce
		end
	end
	write(rig, { `Muslo{s}`, `Pierna{s}`, `Tobillo{s}`, `Pie{s}` }, pitch, roll)
end

-- Las cuatro patas. ctx.height: el alto, por si el modelo no trae BaseHeight.
function Patas.apply(rig: Rig.Rig, p: Pose, height: number, tr: Trunk)
	local geo = Plano.geometry(rig, height)
	if not geo then
		return
	end
	front(rig, geo, p, tr, "Izq", 1, "L")
	front(rig, geo, p, tr, "Der", -1, "R")
	hind(rig, geo, p, tr, "Izq", 1, "L")
	hind(rig, geo, p, tr, "Der", -1, "R")
end

Patas.cycle = Plano.cycle

return table.freeze(Patas)
