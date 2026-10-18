--!strict
--[[
	Zorro/Cara/Gestos

	Un gesto por emoción (las claves emo* de la pose, 0..1). Cada gesto dice
	cómo quedan los huesos de la cara y qué suma a las orejas, la mandíbula y el
	ladeo de la cabeza; las emociones se mezclan por peso y la calma es todo en
	cero (la cara del reposo).
		lid        párpado: 0 abierto .. 1 cerrado
		brow       la ceja (el párpado abierto) inclinada: + el lado de adentro
		           baja (enojo), - sube (sorpresa, ternura)
		tip        punta de las orejas: + se dobla adelante, - atrás
		blink      cuánto parpadea solo (1 = normal; la sorpresa abre los ojos)
		earL, earR, jaw, tilt   se suman a la pose ANTES de Pose.apply
	smooth(memo, pose, dt)  suaviza las emo* en el lugar: pasa de un gesto a otro
	                        en ~0.2 s, aunque la conducta las cambie de golpe
	add(pose)               suma orejas, mandíbula y ladeo de la mezcla
	face(pose)              lid, brow, tip y blink de la mezcla (para Zorro/Cara)
	Lo llama Zorro/Mirada.add (corre antes de Pose.apply) y Zorro/Cara lee face().
]]

local Resorte = require(script.Parent.Parent.Parent.Resorte)

export type Pose = { [string]: number }
export type Memo = { [string]: Resorte.Resorte }
export type Face = { lid: number, brow: number, tip: number, blink: number }

type Gesto = {
	lid: number,
	brow: number,
	tip: number,
	blink: number,
	earL: number,
	earR: number,
	jaw: number,
	tilt: number,
}

-- Resorte sin rebote de cada emoción: arranca y frena suave y llega al 95 % en ~0.2 s.
local SMOOTH_HZ = 3.5

-- La tabla de gestos (docs/guia_crear_monstruo.md, 7, capa 4). Asimetría: el asco
-- echa una oreja más que la otra; el sueño deja una más caída.
local GESTOS: { [string]: Gesto } = {
	emoFeliz = { -- ojos entornados de gusto, orejas arriba, boca entreabierta
		lid = 0.3,
		brow = -0.1,
		tip = 0.15,
		blink = 1,
		earL = 0.2,
		earR = 0.2,
		jaw = 0.22,
		tilt = 0.06,
	},
	emoEnojo = { -- ceño (ceja hacia adentro), orejas planas atrás, enseña los dientes
		lid = 0.25,
		brow = 0.3,
		tip = -0.45,
		blink = 0.7,
		earL = -0.5,
		earR = -0.5,
		jaw = 0.12,
		tilt = 0,
	},
	emoSorpresa = { -- ojos bien abiertos (casi no parpadea), orejas adelante, boca abierta
		lid = 0,
		brow = -0.2,
		tip = -0.2,
		blink = 0.15,
		earL = 0.6,
		earR = 0.6,
		jaw = 0.3,
		tilt = 0,
	},
	emoSueno = { -- párpados a medias, parpadeo lento, orejas caídas y la cabeza ladeada
		lid = 0.55,
		brow = -0.05,
		tip = 0.4,
		blink = 0.6,
		earL = -0.25,
		earR = -0.35,
		jaw = 0,
		tilt = 0.08,
	},
	emoAsco = { -- entrecierra los ojos, arruga la ceja, una oreja atrás, aparta la cabeza
		lid = 0.4,
		brow = 0.15,
		tip = -0.2,
		blink = 0.8,
		earL = -0.45,
		earR = -0.1,
		jaw = 0.16,
		tilt = -0.1,
	},
}
local KEYS = { "emoFeliz", "emoEnojo", "emoSorpresa", "emoSueno", "emoAsco" }

local Gestos = {}

Gestos.KEYS = KEYS

function Gestos.smooth(memo: Memo, pose: Pose, dt: number)
	for _, key in KEYS do
		local target = math.clamp(pose[key] or 0, 0, 1)
		local s = memo[key]
		if s or target > 0 then
			s = s or Resorte.new()
			memo[key] = s
			pose[key] = math.clamp(Resorte.step(s, target, dt, SMOOTH_HZ, 1), 0, 1)
		end
	end
end

-- La mezcla de los gestos, campo por campo. Si las emociones suman más de 1 se
-- reparten (dos gestos llenos no dan el doble de gesto); lo que falta para 1 es
-- calma (todo en cero, parpadeo normal).
local function blend(pose: Pose): Gesto
	local total = 0
	for _, key in KEYS do
		total += math.clamp(pose[key] or 0, 0, 1)
	end
	local share = math.max(1, total)
	local out: Gesto =
		{ lid = 0, brow = 0, tip = 0, blink = 0, earL = 0, earR = 0, jaw = 0, tilt = 0 }
	for _, key in KEYS do
		local w = math.clamp(pose[key] or 0, 0, 1) / share
		if w > 0 then
			local g = GESTOS[key]
			out.lid += g.lid * w
			out.brow += g.brow * w
			out.tip += g.tip * w
			out.blink += g.blink * w
			out.earL += g.earL * w
			out.earR += g.earR * w
			out.jaw += g.jaw * w
			out.tilt += g.tilt * w
		end
	end
	out.blink += 1 - total / share
	return out
end

function Gestos.add(pose: Pose)
	local g = blend(pose)
	for field, value in { earL = g.earL, earR = g.earR, jaw = g.jaw, tilt = g.tilt } do
		if value ~= 0 then
			pose[field] = (pose[field] or 0) + value
		end
	end
end

function Gestos.face(pose: Pose): Face
	local g = blend(pose)
	return { lid = g.lid, brow = g.brow, tip = g.tip, blink = g.blink }
end

return table.freeze(Gestos)
