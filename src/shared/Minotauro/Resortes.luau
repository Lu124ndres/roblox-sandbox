--!strict
--[[
	Minotauro/Resortes

	Acción secundaria: orejas, cola, mandíbula y faldón siguen al cuerpo con
	retraso, como si colgaran de resortes (follow-through y overlap). Cada
	canal persigue su valor de la pose más lo que lo empuja la inercia:
		- al subir el cuerpo, orejas, cola y faldón se quedan abajo; al bajar,
		  se quedan arriba; al frenar de golpe (caer de un salto) se sacuden y la
		  mandíbula rebota;
		- al girar o mecerse, la cola y las tiras de los costados se van al revés;
		- la cola es una cadena: cada segmento más blando que el anterior, así la
		  punta llega tarde.
	El faldón de adelante nunca baja de lo que pide el muslo (Cuerpo.skirt):
	lo empuja la pierna y vuelve con el resorte.
	Rebote y rigidez salen de la etapa (Etapas: bounce y pace): el becerro rebota
	y la forma final casi no.
]]

local Cuerpo = require(script.Parent.Cuerpo)
local Etapas = require(script.Parent.Etapas)

type Spring = { x: number, v: number }
export type Resortes = {
	springs: { [string]: Spring },
	last: { [string]: number },
	speed: { [string]: number },
}

-- canal -> rigidez (1/s²) y cuánto lo empuja cada movimiento del cuerpo, por unidad de
-- velocidad: rise en altos/s (un salto sale a ~1.5), turn y sway en rad/s (~1 en el baile).
-- zeta: amortiguación propia (si no, la de la etapa); el faldón de adelante casi no rebota
-- (con la de la etapa pasaba de 74° a 95° en el pisotón).
type Channel = { k: number, rise: number, turn: number, sway: number, zeta: number? }
local CHANNELS: { [string]: Channel } = {
	earL = { k = 160, rise = -0.4, turn = 0, sway = 0.25 },
	earR = { k = 160, rise = -0.4, turn = 0, sway = -0.25 },
	jaw = { k = 220, rise = -0.25, turn = 0, sway = 0 },
	tailUp = { k = 110, rise = -0.5, turn = 0, sway = 0 },
	-- La cola no puede vibrar a ~6.3 rad/s (el ritmo del baile): entraba en resonancia y se
	-- enroscaba (1.5 rad por segmento en Studio). Por eso es más dura y tiene tope (TAIL_MAX).
	tail1 = { k = 160, rise = 0, turn = -0.25, sway = -0.25 },
	tail2 = { k = 125, rise = 0, turn = -0.3, sway = -0.3 },
	tail3 = { k = 100, rise = 0, turn = -0.35, sway = -0.35 },
	faldonF = { k = 140, rise = -0.5, turn = 0, sway = 0, zeta = 0.6 },
	faldonL = { k = 120, rise = -0.3, turn = 0.1, sway = 0.5 },
	faldonR = { k = 120, rise = -0.3, turn = -0.1, sway = -0.5 },
}
local SUBSTEP = 1 / 120
local TAIL_MAX = 0.9 -- rad por segmento

local Resortes = {}

function Resortes.new(): Resortes
	local springs = {}
	for name in CHANNELS do
		springs[name] = { x = 0, v = 0 }
	end
	return { springs = springs, last = {}, speed = {} }
end

-- Qué tan rápido cambia una clave de la pose (por segundo), suavizado.
local function rate(r: Resortes, pose: { [string]: number }, key: string, dt: number): number
	local now = pose[key] or 0
	local before = r.last[key] or now
	r.last[key] = now
	local raw = (now - before) / dt
	local smooth = r.speed[key] or 0
	smooth += (raw - smooth) * math.min(1, dt * 30)
	r.speed[key] = smooth
	return smooth
end

-- yawRate: rad/s con que gira todo el cuerpo (+ = a su izquierda).
function Resortes.step(
	r: Resortes,
	pose: { [string]: number },
	dt: number,
	yawRate: number,
	profile: Etapas.Profile
)
	local rise = rate(r, pose, "dy", dt) -- alturas por segundo
	local sway = rate(r, pose, "sway", dt)
	local lift = Cuerpo.skirt(pose)
	pose.faldonF = (pose.faldonF or 0) + lift
	local zeta = profile.bounce
	local soft = 1 / (profile.pace * profile.pace)
	local steps = math.max(1, math.ceil(dt / SUBSTEP))
	local h = dt / steps
	for name, c in CHANNELS do
		local s = r.springs[name]
		local target = (pose[name] or 0) + c.rise * rise + c.turn * yawRate + c.sway * sway
		local k = c.k * soft
		local damping = 2 * (c.zeta or zeta) * math.sqrt(k)
		for _ = 1, steps do
			s.v += (k * (target - s.x) - damping * s.v) * h
			s.x += s.v * h
		end
		pose[name] = s.x
	end
	for _, name in { "tail1", "tail2", "tail3" } do
		pose[name] = math.clamp(pose[name], -TAIL_MAX, TAIL_MAX)
	end
	pose.faldonF = math.max(pose.faldonF, lift)
	pose.faldonL = math.max(pose.faldonL, -0.2) -- más adentro tocaría el muslo
	pose.faldonR = math.max(pose.faldonR, -0.2)
	pose.jaw = math.max(pose.jaw, 0)
end

return table.freeze(Resortes)
