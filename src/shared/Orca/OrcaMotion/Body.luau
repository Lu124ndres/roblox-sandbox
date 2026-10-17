--!strict
--[[
	OrcaMotion/Body

	La altura, el cabeceo, el giro sobre su eje y la boca de la orca, cuadro a
	cuadro. Mezcla el nado de crucero (respirar, inclinarse en las curvas,
	bambolearse según su etapa), la pose de comer (sacar la cabeza y abrir la
	boca), la del truco que esté haciendo y, encima, la de su animación al
	comer (Comer: reacciones grandes que mandan como un truco y gestos que se
	suman a la cabeza, la boca, las aletas y la cola). Usa resortes amortiguados:
	el cuerpo llega un poco pasado y se acomoda, como algo pesado en el agua
	(en el aire sigue la parábola exacta del truco).
]]

local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Comer = require(script.Parent.Comer)
local Rig = require(script.Parent.Rig)
local Tricks = require(script.Parent.Tricks)

export type Body = {
	depth: number, -- centro sobre el agua (studs)
	depthSpeed: number,
	pitch: number,
	pitchSpeed: number,
	roll: number,
	rollSpeed: number,
	jaw: number,
	vy: number, -- studs/s
	phase: number, -- fase del aleteo
}
export type Input = {
	profile: Perfil.Profile,
	height: number,
	now: number,
	cruiseDepth: number, -- altos del modelo
	floor: number, -- studs: no baja más que esto
	speed: number, -- studs/s en el plano
	cruise: number, -- velocidad de crucero
	turn: number,
	feeding: number, -- 0..1
	close: number, -- 0..1: ya llegó a la orilla
	trick: Tricks.Pose?,
	weight: number, -- 0..1: cuánto manda el truco
	biting: boolean, -- cierra la boca (llegó un pez)
	anger: number,
	meal: Comer.Out?, -- su animación al comer
	rig: Rig.Rig?, -- si está, se animan sus huesos
}

local Body = {}

function Body.new(depth: number): Body
	return {
		depth = depth,
		depthSpeed = 0,
		pitch = 0,
		pitchSpeed = 0,
		roll = 0,
		rollSpeed = 0,
		jaw = 0,
		vy = 0,
		phase = 0,
	}
end

-- Resorte amortiguado (frecuencia en Hz, amortiguación 1 = sin pasarse).
local function spring(
	x: number,
	v: number,
	target: number,
	dt: number,
	hz: number,
	damping: number
): (number, number)
	local w = 2 * math.pi * hz
	v += (w * w * (target - x) - 2 * damping * w * v) * dt
	return x + v * dt, v
end

local function mix(a: number, b: number?, w: number): number
	return if b then a + (b - a) * w else a
end

function Body.step(body: Body, dt: number, input: Input)
	local p, h = input.profile, input.height
	local trick: Tricks.Pose = input.trick or {}
	local w = input.weight
	local meal = input.meal
	local big: Tricks.Pose = meal and meal.pose or {}
	local bw = if meal then meal.weight else 0
	local add = if meal then meal.add else Comer.zero
	local rise = input.feeding * input.close
	-- Crucero (y comer): respira, levanta la cabeza para comer, se inclina en las curvas.
	local cruiseDepth = input.cruiseDepth
		+ (p.feed.rise - input.cruiseDepth) * rise
		+ math.sin(input.now * 2) * 0.025 * rise
	local cruisePitch = math.atan2(body.vy, math.max(input.speed, 2)) * 0.7 * (1 - rise)
		+ p.feed.pitch * rise
	local cruiseRoll = math.clamp(input.turn * p.swim.bank, -0.45, 0.45)
		+ math.sin(input.now * p.swim.beat * 1.4) * p.swim.wiggle * (1 - rise)
		+ math.sin(input.now * 6) * p.feed.wiggle * rise
		+ math.sin(input.now * 23) * input.anger * 0.05
	local wantDepth =
		math.max(mix(mix(cruiseDepth, trick.depth, w), big.depth, bw) * h, input.floor)
	local wantPitch = mix(mix(cruisePitch, trick.pitch, w), big.pitch, bw)
	-- Las vueltas completas no se deshacen: sin truco se cuenta desde la vuelta actual.
	if w == 0 and bw == 0 then
		body.roll = Tricks.wrap(body.roll)
	end
	local turns = math.round((body.roll - cruiseRoll) / (2 * math.pi)) * 2 * math.pi
	local wantRoll = mix(mix(cruiseRoll + turns, trick.roll, w), big.roll, bw)
	local before = body.depth
	if (trick.air and w > 0.9) or (big.air and bw > 0.9) then
		-- Guarda la velocidad: al volver al agua el resorte sigue el mismo impulso.
		body.depthSpeed = (wantDepth - body.depth) / dt
		body.pitchSpeed = (wantPitch - body.pitch) / dt
		body.rollSpeed = (wantRoll - body.roll) / dt
		body.depth, body.pitch, body.roll = wantDepth, wantPitch, wantRoll
	else
		-- Pasos cortos: el resorte es estable aunque bajen los cuadros por segundo.
		local steps = math.ceil(dt / (1 / 60))
		local sub = dt / steps
		local quick = if math.max(w, bw) > 0.5 then 3 else 1
		for _ = 1, steps do
			body.depth, body.depthSpeed =
				spring(body.depth, body.depthSpeed, wantDepth, sub, 0.55 * quick, 0.85)
			body.pitch, body.pitchSpeed =
				spring(body.pitch, body.pitchSpeed, wantPitch, sub, 0.9 * quick, 0.8)
			body.roll, body.rollSpeed =
				spring(body.roll, body.rollSpeed, wantRoll, sub, 0.8 * quick, 0.75)
		end
	end
	body.vy = (body.depth - before) / dt

	-- Boca: al comer abierta y mordisqueando (se cierra de golpe cuando llega un pez).
	local wantJaw = 0.04 + 0.04 * math.sin(input.now * 0.9) -- respira con la boca apenas abierta
	if input.feeding > 0.5 then
		wantJaw = p.feed.jaw * (0.78 + 0.22 * math.sin(input.now * p.feed.chew * math.pi * 2))
	end
	wantJaw = math.max(0, mix(mix(wantJaw, trick.jaw, w), big.jaw, bw) + add.jaw)
	if input.biting then
		wantJaw = 0
	end
	body.jaw += (wantJaw - body.jaw) * (1 - math.exp(-dt * (if input.biting then 30 else 10)))

	-- Huesos: onda de nado (más lenta y ancha al planear), cola, cabeza, boca, aletas.
	local rig = input.rig
	if rig then
		local glide = 1 - p.swim.glide * (0.5 + 0.5 * math.sin(input.now * math.pi * 2 / 7))
		local pace = input.speed / input.cruise
		local effort = (0.45 + pace * 0.75 + input.anger * 0.4) * glide * p.swim.amplitude
		effort = mix(effort, if trick.effort then trick.effort * p.swim.amplitude else nil, w)
		effort = mix(effort, if big.effort then big.effort * p.swim.amplitude else nil, bw)
		body.phase += dt * math.pi * 2 * p.swim.beat * (0.45 + pace * 0.55 + input.anger * 0.5)
		Rig.apply(rig, {
			phase = body.phase,
			effort = effort * (1 - 0.5 * input.close),
			turn = input.turn,
			jaw = body.jaw,
			fins = -0.25 * input.feeding + (trick.fins or 0) * w + (big.fins or 0) * bw + add.fins,
			flap = p.swim.flap,
			head = 0.12 * input.close + (trick.head or 0) * w + (big.head or 0) * bw + add.head,
			tail = (trick.tail or 0) * w + (big.tail or 0) * bw + add.tail,
			pitchSpeed = body.pitchSpeed,
			rollSpeed = body.rollSpeed,
			waveIzq = add.waveIzq,
			waveDer = add.waveDer,
		}, dt)
	end
end

return table.freeze(Body)
