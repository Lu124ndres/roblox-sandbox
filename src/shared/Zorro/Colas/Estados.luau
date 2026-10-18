--!strict
--[[
	Zorro/Colas/Estados

	Los ángulos objetivo (fan, fold; ver Medidas) de cada tramo de una cola para
	la mezcla de estados del momento. Los resortes de Cadena los persiguen, así
	que aquí nada tiene que ser suave en el tiempo salvo lo que ya viene suave
	(la Mezcla, el abanico y la onda).
		reposo    abanico relajado y algo bajo (lo que queda sin alerta ni carrera)
		alerta    abierto y alto; la onda se achica y tiembla un poco
		abanico   lucirse: el borde se abre (open: el resorte de cada cola, que se
		          pasa un poco) y la punta rompe hacia afuera como una ola
		correr    se pliegan atrás (corriente hacia atrás), cada una en su capa
		envolver  sentado: cada cola baja por su costado (las del centro, por
		          `lado`) y la punta se curva hacia adelante, alrededor de las patas
		enroscar  dormido: más abajo y más curvadas, la punta hacia la nariz; la
		          onda casi se apaga y queda la respiración
		          (con una sola cola, la cría, va entera hacia `lado`)
		meneo     contento: rápido, de la raíz a la punta (más rápido con gusto)
		sacudida  onda fuerte de la raíz a la punta
		latigazo  carga y golpe (Onda.pulse) que viaja hacia la punta
	Un giro total del abanico se reparte entre los tramos (un poco más en la raíz):
	ninguna junta carga sola con todo (tope de 45° por junta, en Cadena).
	drive: el empuje del cuerpo (inercia, arrastre) por tramo, más fuerte en la punta.
]]

local Etapas = require(script.Parent.Parent.Etapas)
local Medidas = require(script.Parent.Medidas)
local Onda = require(script.Parent.Onda)
local Tipos = require(script.Parent.Tipos)

local TAU = math.pi * 2
local WAVE = 0.15 -- rad por tramo de la onda de reposo (en la punta)
-- La de plegar, en proporción: cada cola vive en su capa de profundidad (el abanico gira
-- dentro de ella); plegar la saca de la capa, así que esa onda va chica.
local FOLD_WAVE = 0.25
-- Tope del pliegue total de una cola (la suma de sus tramos): pasados ~90° la punta cruza
-- al otro lado del abanico, sea cual sea la forma de la cola. Con el empuje de la carrera
-- y el enroscado de dormir la suma podía pasar de 2 rad.
local FOLD_MAX = 1.2
local MAX_SPREAD = 1.75 -- el abanico abierto no pasa de 100° de la vertical
-- side: a qué ángulo del abanico bajan las del borde; spread: cuánto más arriba quedan
-- las del centro (así no se cruzan); root: pliegue atrás en la raíz; curl: por tramo
-- desde el segundo (- = hacia adelante, alrededor del cuerpo; crece hacia la punta).
-- Medido con las poses del zorro v2 (tools/blender/zorro_v2_poses.py): con más curl la
-- punta de la cola de abajo pasa por la capa de la del medio y se cruzan.
local WRAP = { side = 1.75, spread = 0.9, root = 0, curl = -0.25 } -- sentado
local CURL = { side = 1.95, spread = 0.95, root = -0.2, curl = -0.25 } -- dormido
-- Correr: se pliegan atrás sin juntarse (juntarlas las cruza).
local RUN_ALPHA, RUN_FOLD = 0, 0.2
local CENTER = 0.15 -- |out| menor: cola del centro, baja por `lado`
local BREATH_SECONDS = 4.6

local Estados = {}

-- Cómo se reparte un giro total entre n tramos: spread (parejo, algo más en la raíz)
-- y root (casi todo en los primeros: el abanico se abre desde la cadera).
local function weights(n: number): ({ number }, { number })
	local spread, root = {}, {}
	local sumSpread, sumRoot = 0, 0
	for j = 1, n do
		local u = if n > 1 then (j - 1) / (n - 1) else 0
		spread[j] = 1 - 0.35 * u
		root[j] = (1 - u) ^ 2 + 0.08
		sumSpread += spread[j]
		sumRoot += root[j]
	end
	for j = 1, n do
		spread[j] /= sumSpread
		root[j] /= sumRoot
	end
	return spread, root
end
local cache: { [number]: { { number } } } = {}
local function weightsFor(n: number): ({ number }, { number })
	local hit = cache[n]
	if not hit then
		local spread, root = weights(n)
		hit = { spread, root }
		cache[n] = hit
	end
	return hit[1], hit[2]
end

-- Ángulo total del abanico que piden envolver y enroscar (y cuánto pesan juntos).
local function wrapped(c: Medidas.Cola, m: Tipos.Mezcla): (number, number, number)
	local total = m.envolver + m.enroscar
	local k = if total > 1 then 1 / total else 1
	local e, s = m.envolver * k, m.enroscar * k
	local side = if math.abs(c.out) > CENTER then math.sign(c.out) else m.lado
	local function toward(p: typeof(WRAP)): number
		-- Una cola sola no deja lugar a otras: baja entera por su costado (lado) y rodea
		-- el cuerpo por ahí; si no, el enroscado la cerraría sobre el lomo.
		local spread = if c.solo then 0 else p.spread
		return side * (p.side - (1 - math.abs(c.out)) * spread) - c.angle
	end
	return e * toward(WRAP) + s * toward(CURL), e, s
end

function Estados.targets(
	c: Medidas.Cola,
	m: Tipos.Mezcla,
	open: number,
	driveFan: number,
	driveFold: number,
	profile: Etapas.Profile,
	t: number,
	fine: boolean,
	fanOut: { number },
	foldOut: { number }
)
	local n = c.n
	local spreadW, rootW = weightsFor(n)
	local relax = (1 - m.alerta) * (1 - m.correr)
	local wrapAlpha, e, s = wrapped(c, m)
	local free = 1 - e - s -- lo que queda de los otros estados al envolver o enroscar
	local alpha = (-0.12 * relax + 0.15 * m.alerta + RUN_ALPHA * m.correr) * c.out * free
		+ wrapAlpha
	local fold = 0.15 * relax - 0.25 * m.alerta + RUN_FOLD * m.correr - 0.2 * open
	-- Abre más las del medio del lado y casi nada las que ya están de costado: el
	-- orden se mantiene y el borde no pasa de MAX_SPREAD.
	local room = math.max(0, 1 - math.abs(c.angle) / MAX_SPREAD)
	local opening = open * profile.abanico * c.out * room * free
	local amp = WAVE
		* profile.fuerza
		* m.calma
		* (1 - 0.3 * math.min(open, 1)) -- luciéndose sostiene el abanico
		* (1 - 0.6 * m.alerta)
		* (1 - 0.8 * e)
		* (1 - 0.95 * s)
		* (1 + 0.3 * m.correr)
	local ritmo = profile.ritmo
	local outward = math.sign(c.out)
	local breath = s * 0.03 * math.sin(TAU * t / BREATH_SECONDS)
	for j = 1, n do
		local u = if n > 1 then (j - 1) / (n - 1) else 0
		local reach = j / n
		local tipward = 0.5 + 0.5 * reach
		local a = amp * (0.55 + 0.45 * reach)
		local fanJ = (alpha - wrapAlpha) * spreadW[j]
			+ wrapAlpha * (spreadW[j] + rootW[j]) / 2
			+ opening * rootW[j]
		local foldJ = fold * spreadW[j] - m.alto * (if j == 1 then 0.35 else 0.08) + breath
		if j == n then
			fanJ += 0.12 * open * outward * math.sqrt(room) -- la punta rompe hacia afuera
		end
		if j == 1 then
			foldJ += e * WRAP.root + s * CURL.root
		else
			foldJ += (e * WRAP.curl + s * CURL.curl) * (0.4 + 0.6 * u)
		end
		fanJ += a * Onda.fan(c, t, j, ritmo, fine)
		foldJ += FOLD_WAVE * a * Onda.fold(c, t, j, ritmo, fine)
		if m.alerta > 0 then
			fanJ += m.alerta * 0.02 * math.sin(TAU * 3.1 * t + c.phases[6] - j * 0.4)
		end
		if m.meneo > 0 then
			local wag = Onda.wag(c, t, j, ritmo, m.gusto)
			fanJ += m.meneo * 0.15 * profile.fuerza * (0.6 + 0.4 * reach) * wag
		end
		if m.sacudida > 0 then
			fanJ += m.sacudida * 0.3 * tipward * Onda.shake(c, t, j, ritmo)
			foldJ += m.sacudida * 0.1 * tipward * Onda.shake(c, t + 0.07, j, ritmo)
		end
		local whip = m.latigazo
		if whip then
			local tau = t - whip - (j - 1) * 0.05
			foldJ += profile.latigo * 0.3 * (0.6 + 0.4 * reach) * Onda.pulse(tau)
		end
		fanOut[j] = fanJ + driveFan * tipward
		foldOut[j] = foldJ + driveFold * tipward
	end
	local total = 0
	for j = 1, n do
		total += foldOut[j]
	end
	if math.abs(total) > FOLD_MAX then
		local k = FOLD_MAX / math.abs(total)
		for j = 1, n do
			foldOut[j] *= k
		end
	end
end

return table.freeze(Estados)
