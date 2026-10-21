--!strict
--[[
	OrcaMotion/Rig/Columna

	La columna de la orca v2 (Raiz > Pecho > Cola1..Cola5 > AletaCola) nadando
	como un cetáceo de verdad:
		- Onda dorsoventral: el cuerpo sube y baja como una onda h(s) que
		  viaja hacia atrás (s = 0 en la nariz, 1 en la punta de la cola). Su
		  alto crece desde atrás de la dorsal (Cola1) hacia la cola con una
		  curva cuadrática; adelante queda un resto chico (HEAD_HEAVE). Cada
		  tramo toma la pendiente de la cuerda entre sus juntas y cada hueso
		  gira la diferencia con su padre: casi nada en el Pecho, lo grande en
		  Cola3..Cola5, y el retraso de fase sale solo del largo de la onda.
		- Paleta: las aletas de la cola no siguen la onda, van ~90° adelantadas
		  al subir y bajar (en la subida, nariz arriba), con un ángulo menor que
		  el de su camino: el ángulo de ataque que empuja. Encima, un resorte
		  rápido (la aleta es flexible).
		- Giros: la columna se curva hacia el giro, más en la mitad de atrás, con
		  resortes cada vez más lentos hacia la punta (llega tarde).
		- Acción: arch (lomo), tail (puntas arriba) y bend (curva lateral) pasan
		  por resortes por hueso: la punta llega última.
	Todo se limita contra Limites, por hueso y en la suma de Cola1..Cola5.
	Devuelve el cabeceo que les tocó a Raiz y Pecho, para que la cabeza lo compense.
]]

local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)
local Limites = require(script.Parent.Parent.Limites)
local Huesos = require(script.Parent.Huesos)
local Tipos = require(script.Parent.Tipos)

type Rig = Tipos.Rig

local TAIL = { "Cola1", "Cola2", "Cola3", "Cola4", "Cola5" }
local NEXT = { "Cola2", "Cola3", "Cola4", "Cola5", "AletaCola" } -- la junta donde termina cada tramo
local PITCH_SPRING = { "PCola1", "PCola2", "PCola3", "PCola4", "PCola5" } -- nombres fijos: sin armar textos por cuadro
local YAW_SPRING = { "YCola1", "YCola2", "YCola3", "YCola4", "YCola5" }
local FLUKES = { "AletaColaIzq", "AletaColaDer" }
local AMP_TIP = 0.085 -- medio alto de la onda en la punta, en largos del cuerpo (real: ~0.1)
local HEAD_HEAVE = 0.12 -- lo que queda de la onda adelante (fracción del de la punta)
local WAVE_K = 3.0 -- rad por largo del cuerpo: ~120° de retraso entre la dorsal y la punta
local TREAD_SHIFT = 0.12 -- al sostenerse vertical la onda nace más atrás (solo la cola rema)
local FLUKE_PITCH = 0.42 -- rad: ángulo de la paleta con aletazo de crucero (real: 25-30°)
local FLUKE_LEAD = 0.35 -- rad: adelanto extra que compensa el retraso del resorte de la aleta
local RECOIL = 0.012 -- rad: el cuerpo entero cabecea apenas contra la cola
local TURN_MAX = 1.2 -- rad/s: más giro no curva más
-- Por rad/s de giro: Pecho y luego Cola1..Cola5 (la mitad de atrás se curva más).
local TURN_GAIN = { 0.03, 0.05, 0.08, 0.11, 0.12, 0.11 }
local TURN_HZ = { 2.4, 2.1, 1.85, 1.6, 1.4, 1.25 } -- los resortes llegan más tarde hacia la punta
-- Cómo se reparten arch y bend en Cola1..Cola5: crece hacia la punta, con el frente rígido como una
-- ballena (y así el arco llega más lejos: las juntas de atrás aguantan más, poses.json de la E3).
local SHARE = { 0.1, 0.15, 0.19, 0.25, 0.31 }
local TAIL_LIFT = { 0.1, 0.18, 0.26, 0.32, 0.34 } -- `tail` crece hacia la punta (suma 1.2)
local ACTION_HZ = { 2.6, 2.35, 2.1, 1.9, 1.7 }
local FLUKE_ROLL = 0.06 -- la cola se tuerce un poco hacia la curva, tarde (rad por rad/s)

local function follow(
	rig: Rig,
	name: string,
	target: number,
	dt: number,
	hz: number,
	damping: number
): number
	return Resorte.step(Resorte.get(rig.springs, name, target), target, dt, hz, damping)
end

-- Alto de la onda en s (largos del cuerpo; + = arriba).
local function heave(s: number, phase: number, amp: number, start: number): number
	local grow = math.clamp((s - start) / math.max(1 - start, 0.05), 0, 1)
	local envelope = HEAD_HEAVE + (1 - HEAD_HEAVE) * grow * grow
	return amp * envelope * math.sin(phase - WAVE_K * s)
end

local function slope(
	at: { [string]: number },
	a: string,
	b: string,
	phase: number,
	amp: number,
	start: number
): number
	local sa, sb = at[a], at[b]
	return math.atan(
		(heave(sb, phase, amp, start) - heave(sa, phase, amp, start)) / math.max(sb - sa, 0.01)
	)
end

-- Escala la cadena si la suma se pasa del tope (cada hueso ya está en su rango).
local function fitChain(values: { number }, limit: number)
	local sum = 0
	for _, v in values do
		sum += v
	end
	if math.abs(sum) > limit then
		local k = limit / math.abs(sum)
		for i, v in values do
			values[i] = v * k
		end
	end
end

local function apply(rig: Rig, pose: Tipos.Pose, dt: number): number
	local at, phase = rig.at, pose.phase
	local amp = AMP_TIP * pose.effort
	local start = at.Cola1 + TREAD_SHIFT * (pose.tread or 0)
	local bend = math.clamp(pose.turn, -TURN_MAX, TURN_MAX)
	local arch, extraBend = pose.arch or 0, pose.bend or 0

	-- Raiz y Pecho: el retroceso del cuerpo y la pendiente de adelante (chicos).
	local recoil = -RECOIL * pose.effort * math.sin(phase - WAVE_K * start)
	Huesos.raw(rig, "Raiz", recoil, 0, 0)
	local chestSlope = slope(at, "Pecho", "Cola1", phase, amp, start)
	local chestYaw = follow(rig, "YPecho", bend * TURN_GAIN[1], dt, TURN_HZ[1], 0.7)
	local chestPitch = Huesos.set(rig, "Pecho", chestSlope + 0.03 * (pose.blow or 0), chestYaw, 0)

	-- Cola1..Cola5: onda (pendiente propia menos la del padre) + acción + giro.
	local pitches, yaws = rig.chain.pitch, rig.chain.yaw
	local parent = chestSlope
	for i, name in TAIL do
		local own = slope(at, name, NEXT[i], phase, amp, start)
		local lift = -arch * SHARE[i] + pose.tail * TAIL_LIFT[i]
		local action = follow(rig, PITCH_SPRING[i], lift, dt, ACTION_HZ[i], 0.75)
		local curve = bend * TURN_GAIN[i + 1] + extraBend * SHARE[i]
		local yaw = follow(rig, YAW_SPRING[i], curve, dt, TURN_HZ[i + 1], 0.65)
		pitches[i], yaws[i] = Huesos.limit(name, own - parent + action, yaw, 0)
		parent = own
	end
	fitChain(pitches, Limites.cadenaPitch)
	fitChain(yaws, Limites.cadenaYaw)
	for i, name in TAIL do
		Huesos.set(rig, name, pitches[i], yaws[i], 0)
	end

	-- Aletas de la cola: paleta adelantada a la onda, sobre la pendiente de la Cola5.
	local tip = at.AletaCola
	local paddle = -FLUKE_PITCH * pose.effort * math.cos(phase - WAVE_K * tip + FLUKE_LEAD)
	local want = paddle - parent + (pose.flukes or 0)
	local flukes = follow(rig, "Aletas", want, dt, 3.0, 0.55)
	local twist = follow(rig, "AletasGiro", bend * FLUKE_ROLL, dt, 1.2, 0.6)
	for _, name in FLUKES do
		Huesos.set(rig, name, flukes, 0, twist)
	end
	return recoil + chestPitch
end

return apply
