--!strict
--[[
	Zorro/Rutina/Medir

	La prueba de "mirar al público" (guía, sección 7): simula la rutina `segundos`
	desde `desde` (por defecto, la hora del servidor) cada DT y mide, con el
	coseno entre su frente y la dirección a la puerta del cráter:
		frente       parte del tiempo de frente al sector de la rampa (±60°: > 0.5)
		costado      de costado (entre 60° y 120°)
		espaldas     de espaldas (más de 120°: < -0.5, se le ve la cola)
		maxEspaldas  el tramo más largo seguido de espaldas (s)
		maxDetras    el tramo más largo seguido mirando más allá del costado (> 90°)
		maxNoFrente  el tramo más largo seguido sin estar de frente (s)
		caminando    parte del tiempo caminando
		trucos       segundos de trucos y parte de ellos de frente (trucosFrente)
		lugares      segundos en cada lugar (por el destino del ciclo)
	Es pura (no crea instancias): se puede correr en Edit o en Play.
]]

local Workspace = game:GetService("Workspace")

local Lugares = require(script.Parent.Lugares)
local Tipos = require(script.Parent.Parent.Tipos)

export type Medida = {
	segundos: number,
	frente: number,
	costado: number,
	espaldas: number,
	maxEspaldas: number,
	maxDetras: number,
	maxNoFrente: number,
	caminando: number,
	trucos: number,
	trucosFrente: number,
	lugares: { [string]: number },
}

type PlanLike = {
	position: Vector3,
	yaw: number,
	walk: number,
	spot: string,
	conducta: Tipos.Conducta?,
}
type PlanFn = (now: number, etapa: number, height: number, lista: { Tipos.Conducta }) -> any

local DT = 0.1

local Medir = {}

function Medir.medir(
	plan: PlanFn,
	lista: { Tipos.Conducta },
	etapa: number,
	height: number,
	segundos: number,
	desde: number?
): Medida
	local t0 = desde or Workspace:GetServerTimeNow()
	local door = Lugares.door()
	local front, side, back, walking, tricks, tricksFront = 0, 0, 0, 0, 0, 0
	local runBack, runBehind, runNotFront = 0, 0, 0
	local maxBack, maxBehind, maxNotFront = 0, 0, 0
	local lugares: { [string]: number } = {}
	local steps = math.floor(segundos / DT)
	for i = 0, steps - 1 do
		local p: PlanLike = plan(t0 + i * DT, etapa, height, lista)
		local to = Vector3.new(door.X - p.position.X, 0, door.Z - p.position.Z).Unit
		local dot = Vector3.new(-math.sin(p.yaw), 0, -math.cos(p.yaw)):Dot(to)
		if dot > 0.5 then
			front += DT
		elseif dot >= -0.5 then
			side += DT
		else
			back += DT
		end
		runBack = if dot < -0.5 then runBack + DT else 0
		runBehind = if dot < 0 then runBehind + DT else 0
		runNotFront = if dot <= 0.5 then runNotFront + DT else 0
		maxBack = math.max(maxBack, runBack)
		maxBehind = math.max(maxBehind, runBehind)
		maxNotFront = math.max(maxNotFront, runNotFront)
		if p.walk > 0.05 then
			walking += DT
		end
		local conducta = p.conducta
		if conducta and conducta.tipo == "truco" then
			tricks += DT
			tricksFront += if dot > 0.5 then DT else 0
		end
		lugares[p.spot] = (lugares[p.spot] or 0) + DT
	end
	local total = math.max(steps * DT, DT)
	return {
		segundos = total,
		frente = front / total,
		costado = side / total,
		espaldas = back / total,
		maxEspaldas = maxBack,
		maxDetras = maxBehind,
		maxNoFrente = maxNotFront,
		caminando = walking / total,
		trucos = tricks,
		trucosFrente = if tricks > 0 then tricksFront / tricks else 1,
		lugares = lugares,
	}
end

return table.freeze(Medir)
