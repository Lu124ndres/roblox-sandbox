--!strict
--[[
	OrcaMotion/Path/Ruta

	El plan del recorrido: una cadena de tramos (Tramo) por época de EPOCH segundos.
	Cada época empieza flotando quieta en un punto fijo (Intencion.anchor) y termina
	llegando al de la siguiente, así que todo sale de la hora del servidor y de un hash
	sin estado: cualquier cliente, aunque entre a mitad de partida, arma la misma
	cadena y ve a la orca en el mismo lugar. Dentro de la época la orca "piensa" como
	un animal: elige una intención y un lugar, nada hacia ahí con las maniobras de
	Maniobras, cambia de idea si tarda, descansa, y en los últimos APPROACH segundos
	vuelve al punto de comienzo de la época siguiente y se queda flotando ahí.
	Las cadenas se guardan (son las mismas siempre): solo las de las últimas épocas.
]]

local Intencion = require(script.Parent.Intencion)
local Maniobras = require(script.Parent.Maniobras)
local Rumbo = require(script.Parent.Rumbo)
local Tramo = require(script.Parent.Tramo)

local EPOCH = 300 -- s
local APPROACH = 90 -- s: al final de la época va al punto de la siguiente
local FINAL_REST = 14 -- s: como mínimo flota ahí antes de que empiece la otra época
local SETTLE = 6 -- s: con menos que esto más FINAL_REST, ya se pone a flotar
local NEAR = 0.15 -- radios: llegó al lugar que buscaba
local INTENT_SECONDS = 45 -- s: si no llegó en este tiempo, cambia de idea
local RESTING = 0.25 -- U: más lento que esto ya puede quedarse flotando
local REST_SECONDS = { 10, 10 } -- s: cuánto descansa (mínimo, extra)
local DRIFT = { 0.02, 0.03 } -- radios: cuánto se deja llevar al descansar
local BRAKE_SECONDS = { 4, 2 } -- s: cuánto tarda en frenar para descansar
local MAX_SEGMENTS = 400 -- por si acaso: una época nunca tiene tantos tramos
local KEEP = 3 -- épocas guardadas

local U = Maniobras.U

local Ruta = {}

Ruta.EPOCH = EPOCH

local cache: { [number]: { Tramo.Tramo } } = {}

local function build(epoch: number): { Tramo.Tramo }
	local t, tEnd = epoch * EPOCH, (epoch + 1) * EPOCH
	local x, z, th = Intencion.anchor(epoch)
	local v, mode, wx, wz, since, final = 0, "", x, z, t, false
	local hops = 0
	local gx, gz, gth = Intencion.anchor(epoch + 1)
	local segs: { Tramo.Tramo } = {}
	for i = 0, MAX_SEGMENTS do
		local rem = tEnd - t
		if rem < APPROACH and not final then
			final, mode, wx, wz = true, "paseo", gx, gz
		end
		local function h(field: number): number
			return Rumbo.rnd(epoch, i, 11, field)
		end
		local seg: Tramo.Tramo
		local toGoal = math.sqrt((gx - x) * (gx - x) + (gz - z) * (gz - z))
		if final and (toGoal < NEAR or rem < FINAL_REST + SETTLE) then
			if v > RESTING * U and rem > FINAL_REST + 2 then
				seg = Maniobras.brake(t, x, z, th, v, math.min(5, rem - FINAL_REST))
			else
				table.insert(segs, Maniobras.rest(t, x, z, th, v, rem, 0, gx, gz, gth))
				break
			end
		else
			if not final then
				local reached = math.sqrt((wx - x) * (wx - x) + (wz - z) * (wz - z)) < NEAR
				if mode == "orilla" and reached and hops > 0 then
					hops -= 1
					wx, wz = Intencion.target(epoch, i, "orilla", x, z)
				elseif
					mode == ""
					or mode == "descanso"
					or reached
					or t - since > INTENT_SECONDS
				then
					mode = Intencion.pick(epoch, i, mode)
					wx, wz = Intencion.target(epoch, i, mode, x, z)
					since, hops = t, 1 + math.floor(2 * h(0))
				end
			end
			local room = math.max(rem - FINAL_REST - SETTLE, 1)
			if mode == "descanso" and v > RESTING * U then
				local D = math.min(BRAKE_SECONDS[1] + BRAKE_SECONDS[2] * h(2), room)
				seg = Maniobras.brake(t, x, z, th, v, D)
				mode = "frenar" -- termina de frenar y después descansa
			elseif mode == "descanso" or mode == "frenar" then
				mode = "descanso"
				local D = math.min(REST_SECONDS[1] + REST_SECONDS[2] * h(3), room)
				seg = Maniobras.rest(t, x, z, th, v, D, DRIFT[1] + DRIFT[2] * h(4))
			else
				seg = Maniobras.travel(epoch, i, t, x, z, th, v, mode, wx, wz, room)
			end
		end
		seg.mode = mode
		table.insert(segs, seg)
		if seg.rest then
			x, z, th, v = seg.qx, seg.qz, seg.th0 + seg.dth, 0
		else
			local _
			x, z, _, _, th = Tramo.at(seg, seg.D)
			v = seg.v1
		end
		t += seg.D
	end
	return segs
end

local function chain(epoch: number): { Tramo.Tramo }
	local segs = cache[epoch]
	if not segs then
		segs = build(epoch)
		cache[epoch] = segs
		for old in cache do
			if old < epoch - KEEP + 1 or old > epoch + KEEP then
				cache[old] = nil
			end
		end
	end
	return segs
end

-- El tramo en que está la orca a la hora `t` y cuántos segundos lleva en él.
function Ruta.locate(t: number): (Tramo.Tramo, number)
	local segs = chain(math.floor(t / EPOCH))
	local lo, hi = 1, #segs
	while lo < hi do -- búsqueda binaria
		local mid = (lo + hi + 1) // 2
		if segs[mid].t0 <= t then
			lo = mid
		else
			hi = mid - 1
		end
	end
	local seg = segs[lo]
	return seg, t - seg.t0
end

-- Posición (x, z), velocidad y rumbo del plan a la hora `t`, en radios del lago.
function Ruta.at(t: number): (number, number, number, number, number)
	local seg, tau = Ruta.locate(t)
	return Tramo.at(seg, tau)
end

return table.freeze(Ruta)
