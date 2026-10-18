--!strict
--[[
	Zorro/Rutina/Sonidos

	Los eventos del cuadro (state.events de Zorro, que ZorroStand vuelve sonido y
	efectos), todos con dónde pasaron (at: la base) y si el hábitat es de hielo:
		- los de Comer (catch, glitter, thanks...), tal como llegan;
		- los de la conducta en curso (Tipos.Evento: at = avance 0..1) que cruzó
		  en este cuadro, si la rutina manda (peso > 0.5); si la conducta empezó
		  hace más de LATE (la vio llegar tarde), no suenan los que ya pasaron;
		- las pisadas al caminar: `pisadas` por paso completo (step, con power =
		  cuánto camina y floe = pisa hielo).
	emit devuelve cuántas patas pisaron (para las ondas en el agua).
]]

local Rumbo = require(script.Parent.Parent.Rumbo)
local Rutina = require(script.Parent)

export type Evento = {
	kind: string,
	power: number?, -- rareza del pez (Comer) o cuánto camina (step)
	side: number?, -- 1 su izquierda, -1 su derecha
	at: Vector3?, -- dónde pasó (la base)
	ice: boolean?, -- el hábitat es de hielo
	floe: boolean?, -- pisa un témpano o la roca
}
export type Comida = { kind: string, power: number?, side: number? }
export type Seguimiento = { key: number, u: number, step: number }

local LATE = 0.25 -- s
local TAU = math.pi * 2

local Sonidos = {}

function Sonidos.new(): Seguimiento
	return { key = 0, u = 0, step = 0 }
end

function Sonidos.emit(
	s: Seguimiento,
	out: { Evento },
	comidas: { Comida },
	plan: Rutina.Plan,
	paso: Rumbo.Paso,
	weight: number,
	pisadas: number,
	ice: boolean?
): number
	local at = paso.position
	for _, event in comidas do
		table.insert(
			out,
			{ kind = event.kind, power = event.power, side = event.side, at = at, ice = ice }
		)
	end
	if plan.key ~= s.key then
		s.key, s.u = plan.key, if plan.elapsed < LATE then 0 else plan.u
	end
	local conducta = plan.conducta
	if conducta and weight > 0.5 then
		for _, event in conducta.eventos do
			if event.at > s.u and event.at <= plan.u then
				table.insert(out, { kind = event.kind, at = at, ice = ice })
			end
		end
	end
	s.u = plan.u
	local index = math.floor(paso.walkPhase * pisadas / TAU)
	local stepped = index ~= s.step and paso.walk > 0.2
	s.step = index
	if stepped then
		table.insert(
			out,
			{ kind = "step", power = paso.walk, at = at, ice = ice, floe = paso.floe }
		)
		return 2
	end
	return 0
end

return table.freeze(Sonidos)
