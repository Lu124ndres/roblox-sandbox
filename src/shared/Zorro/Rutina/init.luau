--!strict
--[[
	Zorro/Rutina

	Qué hace el zorro cuando nadie le da de comer, igual en todos los clientes:
	todo sale de la hora del servidor y de Azar, sin estado. El tiempo se parte en
	ciclos de Habitos.ciclo segundos; en el ciclo c (Rutina/Ciclo):
		1. gira en el lugar hacia donde sale;
		2. camina del lugar de c-1 al de c (Rutina/Lugares: témpanos y la roca de
		   Zorro/Guarida que le caben a su etapa) por una ruta que se ve de frente o
		   de costado desde la puerta (Rutina/Ruta), con walk y walkPhase; a veces
		   hace algo mientras camina (olfatea el rastro: Rutina/Paseo);
		3. al llegar gira de frente a la puerta del cráter;
		4. hace sus conductas con pausas quieto entre una y otra (Rutina/Agenda):
		   nunca dos veces seguidas la misma, los trucos de frente.
	Las conductas que dan vueltas (Conductas/Giros) suman su giro al rumbo.
	plan(now, etapa, height, lista) dice dónde está la base (Y: cima del témpano o
	el agua), su rumbo, cuánto camina y gira, y qué conducta hace (u, r, key).
	conductas() es Zorro/Conductas si trae alguna; si no, Rutina/Reserva.
	medir(etapa, segundos, desde?) simula y mide cuánto mira hacia la puerta
	(Rutina/Medir): la prueba de la guía, para correrla en Edit o en Play.
	Modo de prueba de una conducta: Rutina/Probar (atributo ZorroConducta).
]]

local Agenda = require(script.Agenda)
local Ciclo = require(script.Ciclo)
local Habitos = require(script.Parent.Habitos)
local Lugares = require(script.Lugares)
local Medir = require(script.Medir)
local Paseo = require(script.Paseo)
local Probar = require(script.Probar)
local Reserva = require(script.Reserva)
local Tipos = require(script.Parent.Tipos)

export type Plan = {
	cycle: number,
	position: Vector3,
	yaw: number,
	walk: number, -- 0..1: cuánto camina
	walkPhase: number, -- rad
	turning: number, -- 0..1: cuánto gira en el lugar
	floe: boolean, -- pisa un témpano o la roca
	spot: string,
	conducta: Tipos.Conducta?,
	u: number,
	r: number,
	key: number, -- única por turno (0 si no hace nada)
	elapsed: number, -- segundos desde que empezó la conducta
}
type Giro = (u: number, etapa: number, r: number) -> number

local TAU = math.pi * 2
local PROBE = 0.05 -- s: para medir cuánto gira
local LOOK_BACK = 4 -- ciclos hacia atrás para saber qué hizo antes del paseo

local Rutina = {}

Rutina.ALTOS = table.freeze({ 16.5, 44, 82.5, 165 }) -- alto de cada etapa (studs)

local function wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end

local loaded: { Tipos.Conducta }? = nil
local giros: ((nombre: string) -> Giro?)? = nil

-- Zorro/Conductas (una lista de Tipos.Conducta) o, si no está o viene vacía, la reserva.
function Rutina.conductas(): { Tipos.Conducta }
	if loaded then
		return loaded
	end
	local list: { Tipos.Conducta } = Reserva
	local found = script.Parent:FindFirstChild("Conductas")
	if found and found:IsA("ModuleScript") then
		local ok, result = pcall(require, found)
		if ok and type(result) == "table" and #result > 0 then
			list = result :: any
		end
		local module = found:FindFirstChild("Giros")
		if module and module:IsA("ModuleScript") then
			local okGiros, result2: any = pcall(require, module)
			if okGiros and type(result2) == "table" and type(result2.de) == "function" then
				giros = result2.de
			end
		end
	end
	loaded = list
	return list
end

-- Cuánto gira el cuerpo la conducta (perseguir la cola), sobre el rumbo con que empezó.
local function spin(conducta: Tipos.Conducta?, u: number, etapa: number, r: number): number
	local de = giros
	local giro = if conducta and de then de(conducta.nombre) else nil
	return if giro then giro(u, etapa, r) else 0
end

-- Lo que hace mientras camina en el ciclo c (se elige una vez y queda en el ciclo).
local function paseo(
	k: Ciclo.Ciclo,
	c: number,
	etapa: number,
	height: number,
	lista: { Tipos.Conducta }
): Agenda.Turno?
	if not k.paseado then
		k.paseado = true
		-- Solo si después hace algo en el lugar (así lo de después es su primera
		-- conducta); lo de antes es la última del ciclo anterior que hizo algo.
		local after = Paseo.edge(k.turnos, false)
		if after and not k.shuffle and k.t2 > k.t1 then
			local before = nil
			for back = 1, LOOK_BACK do
				before = Paseo.edge(Ciclo.get(c - back, etapa, height, lista).turnos, true)
				if before then
					break
				end
			end
			k.paseo = Paseo.choose(c, etapa, k.t1 + k.ramp, k.t2 - k.ramp, lista, { before, after })
		end
	end
	return k.paseo
end

function Rutina.plan(now: number, etapa: number, height: number, lista: { Tipos.Conducta }): Plan
	local habito = Habitos.de(etapa)
	local c = math.floor(now / habito.ciclo)
	local t = now - c * habito.ciclo
	local k = Ciclo.get(c, etapa, height, lista)
	local yaw, position, walk, s = Ciclo.at(k, t, habito.giro)
	local ahead = Ciclo.at(k, t + PROBE, habito.giro)
	local plan: Plan = {
		cycle = c,
		position = position,
		yaw = yaw,
		walk = math.clamp(walk, 0, 1),
		walkPhase = s / (habito.zancada * height) * TAU,
		turning = math.clamp(math.abs(wrap(ahead - yaw)) / PROBE / habito.giro, 0, 1),
		floe = false,
		spot = k.to.spot.name,
		conducta = nil,
		u = 0,
		r = 0,
		key = 0,
		elapsed = 0,
	}
	local playing: Agenda.Turno? = nil
	local walking = paseo(k, c, etapa, height, lista)
	if walking and t >= walking.from and t < walking.to then
		playing = walking
	else
		for _, turno in k.turnos do
			if t >= turno.from and t < turno.to and turno.conducta then
				playing = turno
				break
			end
		end
	end
	local test = Probar.find(lista)
	if test then
		local point, facing, u, key, r = Probar.at(now, etapa, test)
		position, plan.yaw, plan.walk, plan.walkPhase, plan.turning = point, facing, 0, 0, 0
		plan.position, plan.conducta, plan.u, plan.key, plan.r = point, test, u, key, r
	elseif playing then
		plan.conducta, plan.r, plan.key = playing.conducta, playing.r, playing.key
		plan.elapsed = t - playing.from
		plan.u = plan.elapsed / (playing.to - playing.from)
	end
	plan.yaw += spin(plan.conducta, plan.u, etapa, plan.r)
	local _, floe = Lugares.ground(position)
	plan.floe = floe
	return plan
end

function Rutina.medir(etapa: number, segundos: number, desde: number?): Medir.Medida
	local e = math.clamp(math.floor(etapa), 1, #Rutina.ALTOS)
	return Medir.medir(Rutina.plan, Rutina.conductas(), e, Rutina.ALTOS[e], segundos, desde)
end

return table.freeze(Rutina)
