--!strict
--[[
	OrcaMotion/Path/Tramo

	Un tramo del recorrido de la orca y dónde está a `tau` segundos de su comienzo.
	Todo va en radios del lago (x, z desde el centro) y con números sueltos, no con
	Vector2/Vector3: esos guardan floats de 32 bits y el plan tiene que dar exactamente
	lo mismo en todos los clientes y en la simulación (tools/orca_recorrido_sim.py).
	Los rumbos son ángulos en el plano: la dirección es (cos th, sin th) = (x, z).

	Dos clases:
		arco      gira a ritmo fijo (`w` rad/s) mientras la velocidad pasa de v0 a v1
		          en línea recta: frena al dar la vuelta, acelera con los aletazos y
		          pierde velocidad planeando;
		descanso  flota casi quieta ("logging"): la posición es un Hermite que llega
		          quieto a (qx, qz) y el rumbo gira suave en los primeros REST_TURN s.
]]

local REST_TURN = 6 -- s: al descansar se acomoda de costado en este tiempo

export type Tramo = {
	rest: boolean,
	mode: string, -- cruce, orilla, paseo, frenar o descanso
	t0: number, -- hora del servidor en que empieza
	D: number, -- duración (s)
	px: number,
	pz: number,
	th0: number,
	-- arco
	v0: number, -- radios/s
	v1: number,
	w: number, -- rad/s
	-- descanso
	qx: number,
	qz: number,
	vx: number, -- velocidad al empezar (radios/s)
	vz: number,
	dth: number, -- cuánto gira el rumbo
}

local Tramo = {}

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
Tramo.smooth = smooth

function Tramo.arc(
	t: number,
	x: number,
	z: number,
	th: number,
	v: number,
	v1: number,
	turn: number,
	D: number
): Tramo
	return {
		rest = false,
		mode = "",
		t0 = t,
		D = D,
		px = x,
		pz = z,
		th0 = th,
		v0 = v,
		v1 = v1,
		w = turn / D,
		qx = 0,
		qz = 0,
		vx = 0,
		vz = 0,
		dth = 0,
	}
end

function Tramo.rest(
	t: number,
	x: number,
	z: number,
	th: number,
	v: number,
	D: number,
	qx: number,
	qz: number,
	dth: number
): Tramo
	return {
		rest = true,
		mode = "descanso",
		t0 = t,
		D = D,
		px = x,
		pz = z,
		th0 = th,
		v0 = 0,
		v1 = 0,
		w = 0,
		qx = qx,
		qz = qz,
		vx = math.cos(th) * v,
		vz = math.sin(th) * v,
		dth = dth,
	}
end

-- Posición (x, z), velocidad (vx, vz) y rumbo a `tau` segundos del comienzo del tramo.
function Tramo.at(seg: Tramo, tau: number): (number, number, number, number, number)
	local D = seg.D
	tau = math.clamp(tau, 0, D)
	if not seg.rest then
		local a, b, w, th0 = seg.v0, (seg.v1 - seg.v0) / D, seg.w, seg.th0
		local speed = a + b * tau
		local th = th0 + w * tau
		local ox, oz
		if math.abs(w) < 1e-5 then
			ox, oz = a * tau + b * tau * tau / 2, 0
		else
			local c, s = math.cos(w * tau), math.sin(w * tau)
			ox = speed * s / w + b * (c - 1) / (w * w)
			oz = (a - speed * c) / w + b * s / (w * w)
		end
		local c0, s0 = math.cos(th0), math.sin(th0)
		local x = seg.px + (ox * c0 - oz * s0)
		local z = seg.pz + (ox * s0 + oz * c0)
		return x, z, math.cos(th) * speed, math.sin(th) * speed, th
	end
	local u = tau / D
	local u2, u3 = u * u, u * u * u
	local h0, h1, h2 = 2 * u3 - 3 * u2 + 1, u3 - 2 * u2 + u, -2 * u3 + 3 * u2
	local d0, d1, d2 = 6 * u2 - 6 * u, 3 * u2 - 4 * u + 1, -6 * u2 + 6 * u
	local mx, mz = seg.vx * D, seg.vz * D
	local x = h0 * seg.px + h1 * mx + h2 * seg.qx
	local z = h0 * seg.pz + h1 * mz + h2 * seg.qz
	local vx = (d0 * seg.px + d1 * mx + d2 * seg.qx) / D
	local vz = (d0 * seg.pz + d1 * mz + d2 * seg.qz) / D
	return x, z, vx, vz, seg.th0 + seg.dth * smooth(tau / math.min(D, REST_TURN))
end

-- Lo más lejos del centro que llega el tramo (revisado cada ~1 s).
function Tramo.reach(seg: Tramo): number
	local worst, n = 0, math.max(2, math.ceil(seg.D))
	for j = 0, n do
		local x, z = Tramo.at(seg, seg.D * j / n)
		worst = math.max(worst, math.sqrt(x * x + z * z))
	end
	return worst
end

return table.freeze(Tramo)
