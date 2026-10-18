--!strict
--[[
	Zorro/Mirada/Episodios

	Qué mira el zorro, en episodios de unos segundos con tiempos de Zorro/Azar:
		jugador  3.5-8 s mirando al jugador (a veces con la cabeza ladeada)
		agua     1.2-2.8 s: abajo, un poco a un lado
		cielo    1.2-2.8 s: arriba
		cola     1.2-2.8 s: bien a un lado, hacia sus colas
		libre    2-5 s sin mirar nada (queda el mirar alrededor del reposo)
	Con el jugador a la vista, el 70 % de los episodios son para él (~90 % del
	tiempo); sin jugador, el 45 % son libres (~70 % del tiempo). La semilla arranca de la hora y
	después cuenta: cada cliente tiene los suyos (es cosmético).
		new()                       un episodio vencido (el primer cuadro elige)
		next(e, now, visible)       elige el siguiente
]]

local Azar = require(script.Parent.Parent.Azar)

export type Episodio = {
	mode: string, -- "jugador", "agua", "cielo", "cola" o "libre"
	ends: number, -- hora en que termina
	n: number, -- número de episodio (semilla de Azar)
	other: Vector2, -- (giro, cabeceo) en rad si no es el jugador
	tilt: number, -- ladeo curioso al mirar al jugador
}

local FOR_PLAYER = 0.7 -- parte de los episodios para el jugador, cuando está a la vista
local FREE = 0.45 -- parte de los episodios libres, sin jugador
local TILT = 0.07 -- rad (la cría aguanta 0.21 de ladeo en total: el reposo ya usa 0.12)

local Episodios = {}

function Episodios.new(): Episodio
	return { mode = "libre", ends = -math.huge, n = 0, other = Vector2.zero, tilt = 0 }
end

function Episodios.next(e: Episodio, now: number, visible: boolean)
	e.n = if e.n == 0 then math.floor(now) % 100000 + 1 else e.n + 1
	local n = e.n
	local r = Azar.unit(n, 1)
	local side = if Azar.unit(n, 2) < 0.5 then -1 else 1
	e.tilt = 0
	if visible and r < FOR_PLAYER then
		e.mode, e.ends = "jugador", now + Azar.between(3.5, 8, n, 3)
		e.tilt = if Azar.unit(n, 4) < 0.4 then TILT * side else 0
		return
	end
	local pick = if visible then (r - FOR_PLAYER) / (1 - FOR_PLAYER) else r
	if not visible and pick < FREE then
		e.mode, e.ends = "libre", now + Azar.between(2, 5, n, 3)
		return
	end
	e.ends = now + Azar.between(1.2, 2.8, n, 3)
	local u = Azar.unit(n, 6)
	local which = Azar.pick(3, n, 5)
	if which == 1 then
		e.mode, e.other = "agua", Vector2.new(side * 0.5 * u, -0.45 - 0.15 * u)
	elseif which == 2 then
		e.mode, e.other = "cielo", Vector2.new(side * 0.35 * u, 0.35 + 0.2 * u)
	else
		e.mode, e.other = "cola", Vector2.new(side * (1.1 + 0.25 * u), -0.1)
	end
end

return table.freeze(Episodios)
