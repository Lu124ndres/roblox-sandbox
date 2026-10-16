--!strict
--[[
	Resorte

	Un número que persigue a otro con peso: acelera hacia el objetivo, llega un
	poco pasado y se acomoda (resorte amortiguado). Es lo que hace que una aleta,
	una cola o un cuello sigan al cuerpo con inercia en vez de copiarlo al
	instante.
		hz        qué tan rápido responde (oscilaciones por segundo)
		damping   1 = llega sin pasarse; menos de 1 = rebota un poco
	Avanza en pasos cortos: es estable aunque bajen los cuadros por segundo.
]]

export type Resorte = { x: number, v: number }

local MAX_STEP = 1 / 120

local Resorte = {}

function Resorte.new(x: number?): Resorte
	return { x = x or 0, v = 0 }
end

function Resorte.step(s: Resorte, target: number, dt: number, hz: number, damping: number): number
	local w = 2 * math.pi * hz
	local steps = math.max(1, math.ceil(dt / MAX_STEP))
	local h = dt / steps
	for _ = 1, steps do
		s.v += (w * w * (target - s.x) - 2 * damping * w * s.v) * h
		s.x += s.v * h
	end
	return s.x
end

-- Un resorte por nombre, creado al primer uso (para cadenas de huesos).
function Resorte.get(set: { [string]: Resorte }, name: string, x: number?): Resorte
	local s = set[name]
	if not s then
		s = Resorte.new(x)
		set[name] = s
	end
	return s
end

return table.freeze(Resorte)
