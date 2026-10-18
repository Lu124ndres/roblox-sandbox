--!strict
--[[
	Dormir: olfatea el suelo y pisotea en el lugar, se sienta y se echa (lie), se
	enrosca hacia un lado (curl, curlSide) con las colas enroscadas hasta la nariz
	(tailCurl, del mismo lado) y cierra los ojos. Dormido respira hondo y lento,
	quieto, y una vez sueña: se le sacude una oreja y, a veces, una pata. Al
	despertar abre los ojos, se desenrosca, bosteza y se para. Todo va en fracciones
	de la duración (12-20 s, más en la forma final), así los eventos caen siempre
	en su lugar.
]]

local C = require(script.Parent.Curvas)
local Tipos = require(script.Parent.Parent.Tipos)

local BREATH = 4.2 -- segundos por respiración dormido

local function duracion(etapa: number, r: number): number
	return C.entre(r, 1, 12, 20) * C.peso(etapa, 0.8, 1, 1.1, 1.3)
end

local conducta: Tipos.Conducta = {
	nombre = "dormir",
	tipo = "postura",
	pesos = { 0.6, 0.6, 0.8, 1.2 },
	quieto = true,
	eventos = { { at = 0.02, kind = "sniff" }, { at = 0.84, kind = "yawn" } },
	duracion = duracion,
	pose = function(u: number, etapa: number, r: number): Tipos.Pose
		local total = duracion(etapa, r)
		local side = C.lado(r, 2)
		local tread = C.beat(u, 0.01, 0.08, 3)
		local lie = C.hold(u, 0.08, 0.15, 0.86, 0.95)
		local curl = C.hold(u, 0.13, 0.2, 0.8, 0.86)
		local sleep = C.hold(u, 0.2, 0.27, 0.78, 0.82)
		local dream = C.azar(r, 3) * 0.3 + 0.35
		local twitch = C.pulse(u, dream, 0.012)
		local kick = if C.azar(r, 4) > 0.5 then C.pulse(u, dream + 0.06, 0.012) else 0
		local yawn = C.hold(u, 0.83, 0.86, 0.88, 0.91)
		local breath = math.sin(2 * math.pi * u * total / BREATH)
		return {
			lookPitch = -0.3 * C.hold(u, 0.005, 0.03, 0.07, 0.12) - 0.1 * curl + 0.25 * yawn,
			lookHold = C.hold(u, 0.005, 0.03, 0.88, 0.96),
			stepFL = 0.25 * math.max(0, tread),
			stepFR = 0.25 * math.max(0, -tread),
			sit = 0.6 * C.hold(u, 0.05, 0.09, 0.1, 0.15),
			lie = lie,
			curl = curl,
			curlSide = side,
			eyesClosed = C.hold(u, 0.18, 0.24, 0.8, 0.83) + 0.6 * yawn,
			emoSueno = 0.9 * C.hold(u, 0.06, 0.16, 0.9, 0.98),
			breathe = 0.05 * sleep * breath,
			earL = -0.3 * sleep + (if side > 0 then 0.35 * twitch else 0),
			earR = -0.22 * sleep + (if side > 0 then 0 else 0.35 * twitch),
			stepHL = 0.2 * kick,
			jaw = 0.8 * yawn,
			tailCurl = curl,
			tailSide = side,
			tailCalm = -0.7 * sleep,
		}
	end,
}

return conducta
