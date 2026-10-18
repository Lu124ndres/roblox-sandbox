--!strict
--[[
	Zorro/Colas/Cadena

	Una cadena de resortes por cola: cada junta persigue su ángulo objetivo (fan y
	fold) con un resorte amortiguado casi crítico, más blando hacia la punta (la
	punta llega más tarde). Cada tramo sigue al anterior con retraso: cuando una
	junta acelera, empuja a la siguiente al revés (inercia), así un golpe en la
	raíz viaja como un látigo hasta la punta. El acople solo va de la raíz a la
	punta, nunca vuelve: no puede entrar en resonancia ni crecer solo.
	Tope de 45° por junta (los tramos del modelo tapan la junta hasta ahí): al
	llegar al tope se frena lo que empuja hacia afuera.
		hz      rigidez de cada junta (oscilaciones por segundo)
		zeta    amortiguación (1 = sin pasarse; 0.8-0.9 = casi crítica)
		substep paso máximo de la integración (1/120 cerca, 1/30 lejos)
]]

local MAX_JOINT = math.rad(45)
local COUPLE = 0.45 -- cuánto empuja la aceleración de una junta a la siguiente

export type Cadena = {
	n: number,
	fanX: { number },
	fanV: { number },
	foldX: { number },
	foldV: { number },
	hz: { number },
}

local Cadena = {}

-- n tramos; la raíz a hzRoot y la punta a hzTip.
function Cadena.new(n: number, hzRoot: number, hzTip: number): Cadena
	local chain: Cadena = { n = n, fanX = {}, fanV = {}, foldX = {}, foldV = {}, hz = {} }
	for j = 1, n do
		local u = if n > 1 then (j - 1) / (n - 1) else 0
		chain.fanX[j], chain.fanV[j], chain.foldX[j], chain.foldV[j] = 0, 0, 0, 0
		chain.hz[j] = hzRoot + (hzTip - hzRoot) * u
	end
	return chain
end

-- Junta fuera del tope: se la vuelve al borde y se frena lo que empuja hacia afuera.
local function limit(chain: Cadena, j: number)
	local a, b = chain.fanX[j], chain.foldX[j]
	local size = math.sqrt(a * a + b * b)
	if size <= MAX_JOINT then
		return
	end
	local k = MAX_JOINT / size
	local na, nb = a / size, b / size
	chain.fanX[j], chain.foldX[j] = a * k, b * k
	local outward = chain.fanV[j] * na + chain.foldV[j] * nb
	if outward > 0 then
		chain.fanV[j] -= outward * na
		chain.foldV[j] -= outward * nb
	end
end

function Cadena.step(
	chain: Cadena,
	fanT: { number },
	foldT: { number },
	zeta: number,
	dt: number,
	substep: number
)
	local steps = math.max(1, math.ceil(dt / substep))
	local h = dt / steps
	for _ = 1, steps do
		local pushFan, pushFold = 0, 0
		for j = 1, chain.n do
			local w = 2 * math.pi * chain.hz[j]
			local k, c = w * w, 2 * zeta * w
			local aFan = k * (fanT[j] - chain.fanX[j]) - c * chain.fanV[j] - COUPLE * pushFan
			local aFold = k * (foldT[j] - chain.foldX[j]) - c * chain.foldV[j] - COUPLE * pushFold
			chain.fanV[j] += aFan * h
			chain.foldV[j] += aFold * h
			chain.fanX[j] += chain.fanV[j] * h
			chain.foldX[j] += chain.foldV[j] * h
			limit(chain, j)
			pushFan, pushFold = aFan, aFold
		end
	end
end

-- Pone la cadena en un estado (sin velocidad): al enlazar, arranca ya en su pose.
function Cadena.reset(chain: Cadena, fanT: { number }, foldT: { number })
	for j = 1, chain.n do
		chain.fanX[j], chain.foldX[j] = fanT[j], foldT[j]
		chain.fanV[j], chain.foldV[j] = 0, 0
		limit(chain, j)
	end
end

Cadena.MAX_JOINT = MAX_JOINT

return table.freeze(Cadena)
