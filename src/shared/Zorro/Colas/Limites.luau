--!strict
--[[
	Zorro/Colas/Limites

	Lo que no puede pasar, después de los resortes:
		gaps(colas)      el ángulo mínimo entre cada cola y su vecina de la derecha
		                 (por el orden de Rig.tails): el 70 % del de reposo, como
		                 mucho 0.45 rad (las puntas curvas de dos vecinas se acercan
		                 más que su ángulo: medido en tools/blender/zorro_v2_poses.py)
		separate(...)    si dos vecinas se acercan más que eso en el abanico, se
		                 abren las dos por igual desde la raíz (la corrección crece
		                 de a poco con la falta: no salta)
		tip(c, fan, fold, k)  dónde quedan el último hueso y la punta (espacio del
		                 pivote, reposo) con los ángulos multiplicados por k
		room(...)        qué fracción de la pose cabe (0..1): 1 si la punta y el
		                 último hueso no entran en el cuerpo (la cápsula de Medidas)
		                 ni bajan de minY; si no, cuánto acercarla al reposo
		                 (búsqueda binaria, 4 pasos)
		fit(...)         el room de todas juntas (el menor): si una choca, todas se
		                 acercan igual al reposo, así dos vecinas no se cruzan. El piso
		                 de cada una nunca sube por encima de su reposo (restLow)
		leer(...)        lo que quedó escrito en cada tramo y lo peor de los
		                 límites (para depurar: Colas.leer y Colas/Prueba)
	La cinemática compone los giros como los huesos: cada junta gira alrededor de
	sus ejes de reposo llevada por las anteriores (D_j = D_{j-1} · R_j).
]]

local Medidas = require(script.Parent.Medidas)

local GAP_SHARE = 0.7
local GAP_MAX = 0.45

local Limites = {}

function Limites.gaps(colas: { Medidas.Cola }): { number }
	local out = {}
	for i = 1, #colas - 1 do
		local rest = colas[i + 1].angle - colas[i].angle
		out[i] = if rest > 0 then math.min(rest * GAP_SHARE, GAP_MAX) else 0
	end
	return out
end

function Limites.separate(colas: { Medidas.Cola }, fan: { { number } }, gaps: { number })
	local count = #colas
	if count < 2 then
		return
	end
	local at, shift = {}, {}
	for i, c in colas do
		local total = c.angle
		for j = 1, c.n do
			total += fan[i][j]
		end
		at[i], shift[i] = total, 0
	end
	for _ = 1, 3 do
		for i = 1, count - 1 do
			local missing = gaps[i] - ((at[i + 1] + shift[i + 1]) - (at[i] + shift[i]))
			if missing > 0 then
				shift[i] -= missing / 2
				shift[i + 1] += missing / 2
			end
		end
	end
	for i, c in colas do
		if shift[i] ~= 0 then
			fan[i][1] += shift[i] * (if c.n > 1 then 0.6 else 1)
			if c.n > 1 then
				fan[i][2] += shift[i] * 0.4
			end
		end
	end
end

function Limites.tip(
	c: Medidas.Cola,
	fan: { number },
	fold: { number },
	k: number
): (Vector3, Vector3)
	local turn = CFrame.identity
	local p, before = c.root, c.root
	for j = 1, c.n do
		turn = turn
			* CFrame.fromAxisAngle(c.fanAxis, fan[j] * k)
			* CFrame.fromAxisAngle(c.foldAxis, fold[j] * k)
		before = p
		p += turn:VectorToWorldSpace(c.segs[j])
	end
	return before, p
end

local function inside(m: Medidas.Medidas, p: Vector3): boolean
	local ab = m.b - m.a
	local u = math.clamp((p - m.a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (m.a + ab * u)).Magnitude < m.radius
end

local function fits(
	c: Medidas.Cola,
	m: Medidas.Medidas,
	fan: { number },
	fold: { number },
	k: number,
	minY: number
): boolean
	local last, tip = Limites.tip(c, fan, fold, k)
	return tip.Y >= minY and last.Y >= minY and not inside(m, tip) and not inside(m, last)
end

-- ¿Cabe la cola en reposo? (si no, el modelo es raro y no se la limita).
function Limites.restFits(c: Medidas.Cola, m: Medidas.Medidas, minY: number): boolean
	local zeros = table.create(c.n, 0)
	return fits(c, m, zeros, zeros, 0, minY)
end

function Limites.room(
	c: Medidas.Cola,
	m: Medidas.Medidas,
	fan: { number },
	fold: { number },
	minY: number
): number
	if fits(c, m, fan, fold, 1, minY) then
		return 1
	end
	local lo, hi = 0, 1
	for _ = 1, 4 do
		local mid = (lo + hi) / 2
		if fits(c, m, fan, fold, mid, minY) then
			lo = mid
		else
			hi = mid
		end
	end
	return lo
end

-- Alto del último hueso o de la punta (el más bajo) en reposo.
function Limites.restLow(c: Medidas.Cola): number
	local zeros = table.create(c.n, 0)
	local last, tip = Limites.tip(c, zeros, zeros, 0)
	return math.min(last.Y, tip.Y)
end

function Limites.fit(
	m: Medidas.Medidas,
	fan: { { number } },
	fold: { { number } },
	restOk: { boolean },
	restLow: { number },
	minY: number
): number
	local out = 1
	for i, cola in m.colas do
		if restOk[i] then
			out = math.min(out, Limites.room(cola, m, fan[i], fold[i], math.min(minY, restLow[i])))
		end
	end
	return out
end

export type Lectura = {
	bones: { [string]: { fan: number, fold: number } },
	maxJoint: number, -- rad: la junta más doblada
	minGap: number, -- rad: lo más cerca que quedan dos vecinas en el abanico
	minTip: number, -- alto de la punta más baja sobre el piso (en altos de la cadera)
	room: { number }, -- por cola: 1 = libre, menos = acercada al reposo por un choque
}

-- written: por cola, los ángulos escritos (fan, fold intercalados por tramo).
function Limites.leer(m: Medidas.Medidas, written: { { number } }, room: { number }): Lectura
	local out: Lectura =
		{ bones = {}, maxJoint = 0, minGap = math.huge, minTip = math.huge, room = room }
	local at = {}
	for i, cola in m.colas do
		local last, total = written[i], cola.angle
		local fan, fold = table.create(cola.n, 0), table.create(cola.n, 0)
		for j, tramo in cola.tramos do
			local a, b = last[2 * j - 1], last[2 * j]
			out.bones[tramo.bone.Name] = { fan = a, fold = b }
			out.maxJoint = math.max(out.maxJoint, math.sqrt(a * a + b * b))
			fan[j], fold[j], total = a, b, total + a
		end
		at[i] = total
		local _, tip = Limites.tip(cola, fan, fold, 1)
		out.minTip = math.min(out.minTip, (tip.Y - m.floor) / m.unit)
	end
	for i = 1, #at - 1 do
		out.minGap = math.min(out.minGap, at[i + 1] - at[i])
	end
	return out
end

return table.freeze(Limites)
