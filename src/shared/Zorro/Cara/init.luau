--!strict
--[[
	Zorro/Cara

	La cara del zorro: el único que escribe Parpado{l} y OrejaPunta{l} (huesos de
	detalle: si el modelo no los tiene, Rig.turn los salta). Lo llama Pose.apply y
	solo trabaja con detalle (cámara cerca y sin modo rápido); al perder el
	detalle deja los dos huesos en reposo una vez y no escribe más.
		párpados  el gesto (Cara/Gestos: lid y la ceja inclinada, brow), más
		          eyesClosed y blink de la pose, más el parpadeo solo (Cara/Parpadeo,
		          el mismo instante en todos los clientes). 1 = cerrado: el párpado,
		          que abierto es una ceja al ras, baja LID_CLOSED rad y tapa el ojo.
		puntas    el doblez del gesto y earTipL/earTipR (+ adelante), con inercia
		          (Cara/Puntas): llegan tarde cuando giran la oreja o la cabeza.
	Las emo* llegan ya suavizadas: Zorro/Mirada.add las pasa por Cara/Gestos antes
	de Pose.apply (y suma ahí lo que el gesto pide a orejas, mandíbula y ladeo).
	Rendimiento: cada hueso se escribe solo si cambió más de EPS rad.
]]

local Gestos = require(script.Gestos)
local Parpadeo = require(script.Parpadeo)
local Puntas = require(script.Puntas)
local Rig = require(script.Parent.Rig)
local Tipos = require(script.Parent.Tipos)

export type Pose = { [string]: number }

-- rad que baja el párpado cerrado, por etapa: el ángulo que más tapa el ojo, medido con
-- tools/blender/zorro_v2_cara_prueba.py (sin choques hasta 1.75 en las cuatro).
local LID_CLOSED = { 1.4, 1.4, 1.65, 1.4 }
local BROW = 0.45 -- rad de alabeo de la ceja con brow = 1
local TIP = 0.6 -- rad de doblez de la punta con tip = 1
local EPS = 0.003 -- rad: menos que esto no se escribe
local SLEEPY_PACE = 0.8 -- con sueño, cada parpadeo dura hasta 1.8 veces más
local SIDES = { "Izq", "Der" }

type Memo = {
	last: { [string]: Vector3 }, -- (cabeceo, giro, alabeo) escrito en cada hueso
	tips: { [string]: Puntas.Punta },
	active: boolean,
}

local memos: { [Rig.Rig]: Memo } = setmetatable({}, { __mode = "k" }) :: any

local Cara = {}

local function memoFor(rig: Rig.Rig): Memo
	local m = memos[rig]
	if not m then
		m = { last = {}, tips = { Izq = Puntas.new(), Der = Puntas.new() }, active = false }
		memos[rig] = m
	end
	return m
end

local function write(rig: Rig.Rig, m: Memo, name: string, pitch: number, roll: number)
	if not rig.bones[name] then
		return
	end
	local value = Vector3.new(pitch, 0, roll)
	local last = m.last[name]
	if last then
		local d = value - last
		if math.max(math.abs(d.X), math.abs(d.Z)) < EPS then
			return
		end
	end
	m.last[name] = value
	Rig.turn(rig, name, pitch, 0, roll)
end

-- Lejos: deja la cara en reposo (una sola vez) y olvida la inercia.
local function rest(rig: Rig.Rig, m: Memo)
	if not m.active then
		return
	end
	m.active = false
	for _, s in SIDES do
		write(rig, m, `Parpado{s}`, 0, 0)
		write(rig, m, `OrejaPunta{s}`, 0, 0)
		Puntas.reset(m.tips[s])
	end
end

-- 0 abierto .. 1 cerrado: el gesto o los ojos cerrados, y encima los parpadeos.
function Cara.lid(p: Pose, now: number, face: Gestos.Face?): number
	local f = face or Gestos.face(p)
	local sleepy = math.clamp(p.emoSueno or 0, 0, 1)
	local auto = Parpadeo.at(now, f.blink, 1 + SLEEPY_PACE * sleepy)
	local lid = math.clamp(math.max(f.lid, p.eyesClosed or 0), 0, 1)
	return lid + (1 - lid) * math.clamp(math.max(auto, p.blink or 0), 0, 1)
end

function Cara.apply(rig: Rig.Rig, p: Pose, ctx: Tipos.Contexto)
	local m = memoFor(rig)
	if not ctx.detail then
		rest(rig, m)
		return
	end
	m.active = true
	local face = Gestos.face(p)
	local lid = Cara.lid(p, ctx.now, face)
	-- Al cerrarse, la ceja vuelve derecha: el párpado tapa el ojo parejo.
	local brow = face.brow * BROW * (1 - lid)
	local closed = LID_CLOSED[math.clamp(ctx.etapa, 1, #LID_CLOSED)]
	for _, s in SIDES do
		local name = `Parpado{s}`
		-- El lado de adentro de la ceja baja con brow > 0 (izquierda: alabeo +).
		local side = rig.side[name] or (if s == "Izq" then -1 else 1)
		write(rig, m, name, -closed * lid, -brow * side)
		local bend = face.tip + (if s == "Izq" then p.earTipL or 0 else p.earTipR or 0)
		local pitch, roll = Puntas.step(m.tips[s], rig, s, -TIP * bend, ctx.etapa, ctx.dt)
		write(rig, m, `OrejaPunta{s}`, pitch, roll)
	end
end

return table.freeze(Cara)
