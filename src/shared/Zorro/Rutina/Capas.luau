--!strict
--[[
	Zorro/Rutina/Capas

	Arma la pose del cuadro sumando las capas (Zorro/Pose), en este orden:
		reposo     respira, se mece, mira alrededor; el paseo de la cabeza cede
		           ante lo que mira la conducta o comer (lookHold)
		comer      la pose de comer (cuando llega y deja de caminar) y lo que suma
		           Comer (bocados, raros, combos, gusto)
		evolución  si está evolucionando
		conducta   la de la rutina, con su peso (entra y sale suave)
		cuerpo     pasitos al girar en el lugar, el paso (walk, walkPhase) y el
		           enojo (emoEnojo: la cara ya echa las orejas)
	lookHold: cuánto ignora la Mirada al jugador; nunca menos que lo que pide comer
	(w, body.look, el lookHold de Comer) y nunca más de 1.
	aplicar() hace el resto del cuadro en el orden del contrato: Mirada.add,
	Pose.apply (tronco, patas y cara) y Colas.step con el cuerpo real (giro,
	avance, subida y bajada: `drop`, lo que baja la base, fracción del alto).
]]

local Colas = require(script.Parent.Parent.Colas)
local Mirada = require(script.Parent.Parent.Mirada)
local Pose = require(script.Parent.Parent.Pose)
local Rig = require(script.Parent.Parent.Rig)
local Rumbo = require(script.Parent.Parent.Rumbo)
local Tipos = require(script.Parent.Parent.Tipos)
local Traduccion = require(script.Parent.Parent.Colas.Traduccion)

export type Entrada = {
	now: number,
	paso: Rumbo.Paso,
	act: Pose.Pose?, -- la pose de la conducta (sin peso)
	weight: number, -- peso de la conducta
	extra: Pose.Pose, -- lo que suma Comer
	take: number, -- cuánto deja la pose de comer (Comer.Body.take)
	look: number, -- Comer.Body.look
	eating: number, -- 0..1: cuánto está comiendo
	biting: boolean,
	evolve: Pose.Pose?,
	stepPhase: number,
	anger: number,
}

local HEAD_KEYS = { "lookYaw", "lookPitch", "tilt" }

local Capas = {}

function Capas.armar(e: Entrada): Pose.Pose
	local act, paso = e.act, e.paso
	local eatHold = math.max(e.extra.lookHold or 0, e.eating, e.look)
	local hold = math.max(if act then (act.lookHold or 0) * e.weight else 0, eatHold)
	local pose = Pose.idle(e.now)
	local k = 1 - math.clamp(hold, 0, 1)
	for _, key in HEAD_KEYS do
		local value = pose[key]
		if value then
			pose[key] = value * k
		end
	end
	Pose.add(pose, Pose.feeding(e.eating * (1 - e.take) * (1 - paso.walk), e.now, e.biting))
	Pose.add(pose, e.extra)
	pose.lookHold = math.max(pose.lookHold or 0, e.eating, e.look)
	if e.evolve then
		Pose.add(pose, e.evolve)
	end
	if act then
		Pose.add(pose, act, e.weight)
	end
	pose.lookHold = math.max(math.min(pose.lookHold or 0, 1), math.min(eatHold, 1))
	Pose.add(pose, Pose.steps(e.stepPhase, paso.turning * (1 - paso.walk)))
	pose.walk, pose.walkPhase = paso.walk, paso.walkPhase
	Pose.add(pose, { emoEnojo = e.anger, lean = -0.1 * e.anger })
	return pose
end

function Capas.aplicar(
	rig: Rig.Rig?,
	colas: Colas.Colas?,
	tracking: Traduccion.Seguimiento,
	mirada: any,
	pose: Pose.Pose,
	ctx: Tipos.Contexto,
	giro: number,
	drop: number,
	anger: number
)
	Mirada.add(pose, ctx, mirada)
	if rig then
		Pose.apply(rig, pose, giro, ctx)
	end
	if colas then
		local body = { dy = drop, shake = pose.shake }
		local move = Traduccion.body(tracking, body, giro, ctx.center, ctx.height, ctx.dt)
		local intent = Traduccion.intent(tracking, pose, anger, nil)
		Colas.step(colas, intent, move, ctx.now, ctx.dt, ctx.detail)
	end
end

return table.freeze(Capas)
