--!strict
--[[
	Zorro/Colas

	Las colas del zorro de agua (1 a 9, de 4 o 5 tramos: las que tenga el
	modelo). SOLO este módulo escribe los huesos Cola*_*: los demás piden un
	Intent y Zorro/init pasa el BodyInfo (Colas/Tipos). Cada cuadro:
		1. Mezcla: el Intent y el cuerpo, suavizados (≥ 0.3 s, nunca de golpe);
		2. Estados: el ángulo objetivo de cada tramo (pose del estado + la onda
		   propia de la cola + el empuje del cuerpo: giro, carrera, salto);
		3. Cadena: los resortes los persiguen (casi críticos, más blandos hacia
		   la punta, con tope de 45° por junta y el látigo de tramo a tramo);
		4. Limites: separación entre vecinas y ninguna punta en el cuerpo ni bajo
		   el agua (si alguna no cabe, todas se acercan al reposo lo justo);
		5. escribe Bone.Transform (solo si cambió más que un umbral).
	detail: la cámara está cerca y no hay modo rápido (lo decide ZorroStand). Lejos
	hace menos trabajo con la misma silueta: pasos de resorte de 1/30 s, la onda
	sin ruido, los choques cada 4 cuadros y un umbral de escritura mayor.
	Depuración: leer(c) da los giros de cada tramo y las medidas de los límites;
	Colas/Prueba simula sin escribir huesos (para execute_luau en Play).
]]

local Etapas = require(script.Parent.Etapas)
local Resorte = require(script.Parent.Parent.Resorte)
local Rig = require(script.Parent.Rig)
local Cadena = require(script.Cadena)
local Estados = require(script.Estados)
local Limites = require(script.Limites)
local Medidas = require(script.Medidas)
local Mezcla = require(script.Mezcla)
local Tipos = require(script.Tipos)

export type Intent = Tipos.Intent
export type BodyInfo = Tipos.BodyInfo

local HZ_ROOT, HZ_TIP = 2.4, 1.1 -- rigidez de la raíz y de la punta (por el peso de la etapa)
local OPEN_DAMPING = 0.5 -- el abanico se pasa ~15 % y vuelve
local OPEN_HZ_CENTER, OPEN_HZ_EDGE = 1.5, 0.75 -- cascada: el centro abre primero
-- Empuje del cuerpo: giro (rad/s), carrera (altos/s), subida (altos/s), frenazo (altos/s²).
-- La carrera pliega poco: plegar saca a cada cola de su capa y las cruza.
local K_TURN, K_RUN, K_RISE, K_ACCEL = 0.15, 0.03, 0.09, 0.025
local NEAR_STEP, FAR_STEP = 1 / 120, 1 / 30
local FAR_CHECK_EVERY = 4
local WRITE_NEAR, WRITE_FAR = 0.0005, 0.004 -- rad: menos que esto no se vuelve a escribir
local FLOOR_STAND, FLOOR_WRAP = 0.3, 0.04 -- las puntas no bajan de esta fracción de la cadera
local ROOM_BACK = 2 -- por segundo: lo que vuelve una cola que se acercó al reposo

export type Colas = {
	rig: Rig.Rig,
	med: Medidas.Medidas,
	profile: Etapas.Profile,
	mezcla: Mezcla.State,
	chains: { Cadena.Cadena },
	opens: { Resorte.Resorte },
	openHz: { number },
	room: { number }, -- el mismo para todas (ver step)
	restOk: { boolean },
	restLow: { number }, -- alto del último hueso o la punta (el más bajo) en reposo
	gaps: { number },
	fan: { { number } },
	fold: { { number } },
	written: { { number } },
	frame: number,
	started: boolean,
	dry: boolean, -- no escribe huesos (Colas/Prueba)
}

local Colas = {}

function Colas.new(rig: Rig.Rig, profile: Etapas.Profile): Colas?
	local med = Medidas.bind(rig)
	if not med or #med.colas == 0 then
		return nil
	end
	local c: Colas = {
		rig = rig,
		med = med,
		profile = profile,
		mezcla = Mezcla.new(),
		chains = {},
		opens = {},
		openHz = {},
		room = {},
		restOk = {},
		restLow = {},
		gaps = Limites.gaps(med.colas),
		fan = {},
		fold = {},
		written = {},
		frame = 0,
		started = false,
		dry = false,
	}
	local minY = med.floor + med.unit * FLOOR_STAND
	for i, cola in med.colas do
		c.chains[i] = Cadena.new(cola.n, HZ_ROOT * profile.peso, HZ_TIP * profile.peso)
		c.opens[i] = Resorte.new(0)
		local edge = math.abs(cola.out)
		c.openHz[i] = (OPEN_HZ_CENTER + (OPEN_HZ_EDGE - OPEN_HZ_CENTER) * edge) * profile.peso
		c.room[i] = 1
		c.restOk[i] = Limites.restFits(cola, med, minY)
		c.restLow[i] = Limites.restLow(cola)
		c.fan[i], c.fold[i] = table.create(cola.n, 0), table.create(cola.n, 0)
		c.written[i] = table.create(cola.n * 2, math.huge)
	end
	return c
end

-- El de un modelo del zorro (su etapa sale del nombre); nil si falta algo.
function Colas.forModel(rig: Rig.Rig?, model: Model?): Colas?
	return if rig and model then Colas.new(rig, Etapas.forModel(model.Name)) else nil
end

local function write(c: Colas, i: number, k: number, eps: number)
	local cola, fan, fold, last = c.med.colas[i], c.fan[i], c.fold[i], c.written[i]
	for j, tramo in cola.tramos do
		local a, b = fan[j] * k, fold[j] * k
		local size = math.sqrt(a * a + b * b)
		if size > Cadena.MAX_JOINT then -- la separación pudo pasarse un poco del tope
			a, b = a * Cadena.MAX_JOINT / size, b * Cadena.MAX_JOINT / size
		end
		if math.abs(a - last[2 * j - 1]) > eps or math.abs(b - last[2 * j]) > eps then
			last[2 * j - 1], last[2 * j] = a, b
			if not c.dry then
				tramo.bone.Transform = CFrame.fromAxisAngle(tramo.fan, a)
					* CFrame.fromAxisAngle(tramo.fold, b)
			end
		end
	end
end

-- now: hora del servidor (la onda es la misma en todos los clientes).
function Colas.step(
	c: Colas,
	intent: Intent,
	body: BodyInfo,
	now: number,
	dt: number,
	detail: boolean
)
	dt = math.clamp(dt, 1 / 240, 0.1)
	c.frame += 1
	local profile, med = c.profile, c.med
	local m = Mezcla.step(c.mezcla, intent, body, dt)
	local rise, accel = Mezcla.vertical(c.mezcla)
	local turn = K_TURN * math.clamp(body.giro, -3, 3) * profile.latigo
	local run = K_RUN * math.clamp(body.avance, 0, 3) * profile.latigo
	local vertical = (K_RISE * rise + K_ACCEL * accel) * profile.latigo
	local open = math.clamp(intent.abanico or 0, 0, 1.5)
	local substep = if detail then NEAR_STEP else FAR_STEP
	for i, cola in med.colas do
		local opened = Resorte.step(c.opens[i], open, dt, c.openHz[i], OPEN_DAMPING)
		local driveFan = turn * cola.turnFan + run * cola.backFan - vertical * cola.upFan
		local driveFold = turn * cola.turnFold + run * cola.backFold - vertical * cola.upFold
		local fan, fold = c.fan[i], c.fold[i]
		Estados.targets(cola, m, opened, driveFan, driveFold, profile, now, detail, fan, fold)
		local chain = c.chains[i]
		if c.started then
			Cadena.step(chain, fan, fold, profile.rebote, dt, substep)
		else
			Cadena.reset(chain, fan, fold) -- arranca ya en su pose, sin saltar desde cero
		end
		for j = 1, cola.n do
			fan[j], fold[j] = chain.fanX[j], chain.foldX[j]
		end
	end
	c.started = true
	Limites.separate(med.colas, c.fan, c.gaps)
	local wrap = math.clamp(m.envolver + m.enroscar, 0, 1)
	local minY = med.floor
		+ med.unit * (FLOOR_STAND + (FLOOR_WRAP - FLOOR_STAND) * wrap)
		+ med.height * (body.bajada or 0) -- sentado o echado, el piso queda más cerca
	local check = detail or c.frame % FAR_CHECK_EVERY == 0
	local eps = if detail then WRITE_NEAR else WRITE_FAR
	if check then
		-- Un solo lugar para todas (Limites.fit): el abanico no se desarma.
		local fit = Limites.fit(med, c.fan, c.fold, c.restOk, c.restLow, minY)
		local back = dt * ROOM_BACK * (if detail then 1 else FAR_CHECK_EVERY)
		local shared = math.min(fit, c.room[1] + back) -- entra al instante, sale de a poco
		for i in med.colas do
			c.room[i] = shared
		end
	end
	for i in med.colas do
		write(c, i, c.room[i], eps)
	end
end

export type Lectura = Limites.Lectura

-- Lo último que escribió (con los límites aplicados), para depurar.
function Colas.leer(c: Colas): Lectura
	return Limites.leer(c.med, c.written, c.room)
end

return table.freeze(Colas)
