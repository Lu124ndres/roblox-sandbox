--!strict
--[[
	Zorro/Comer/Cuerpo

	Lee de la pose de las reacciones lo que mueve al cuerpo entero (Body: giro,
	vuelta, corrimiento, cuánto deja la pose de comer, pisadas, estela) y le
	suma la acción secundaria de los saltos y las vueltas:
		- al subir, colas y orejas se quedan abajo; al bajar, arriba (con un
		  resorte: llegan tarde y se pasan un poco);
		- en el salto mortal las colas se quedan atrás de la vuelta;
		- al girar sobre sí, colas y orejas se arrastran (turn se suma al giro
		  que ya siguen en Zorro/Pose, con tope para que no se enrosquen).
	Y topa lo que varias capas suman de la cara (emo*, puntas de las orejas) y
	de la mirada (lookHold, que también sube con take).
]]

local Pose = require(script.Parent.Parent.Pose)
local Resorte = require(script.Parent.Parent.Parent.Resorte)

local TAU = math.pi * 2
local EMOTIONS = { "emoFeliz", "emoSorpresa", "eyesClosed", "blink" }

export type Body = {
	take: number, -- cuánto deja la pose de comer (0..1)
	spin: number, -- giro sobre sí (rad, + a su izquierda)
	flip: number, -- vuelta hacia atrás (rad)
	runX: number, -- corrimiento en su marco (fracción del alto, -Z al frente)
	runZ: number,
	turn: number, -- rad/s que se suman al giro: colas y orejas se quedan atrás
	stepped: boolean, -- una pata pisó al correr
	trail: number, -- 0..1: estela de agua
	look: number, -- 0..1: mira al jugador de este cliente
	from: Vector3?,
	morsel: number, -- 0..1: mira el bocado (el pez venía de fed)
	fed: Vector3?,
}
export type State = { spin: number, flip: number, dy: number, gait: number, rise: Resorte.Resorte }

local Cuerpo = {}

function Cuerpo.new(): State
	return { spin = 0, flip = 0, dy = 0, gait = 0, rise = Resorte.new() }
end

local function wrap(angle: number): number
	return (angle + math.pi) % TAU - math.pi
end

-- Lee las claves del cuerpo de la pose (Zorro/Pose no las usa) y arma el Body.
function Cuerpo.take(
	s: State,
	pose: Pose.Pose,
	dt: number,
	look: number,
	from: Vector3?,
	fed: Vector3?
): Body
	local spin, flip, dy, gait = pose.spinY or 0, pose.flip or 0, pose.dy or 0, pose.gait or 0
	local spinRate, flipRate = wrap(spin - s.spin) / dt, wrap(flip - s.flip) / dt
	local rise = Resorte.step(s.rise, (dy - s.dy) / dt, dt, 4, 0.7) -- altos por segundo
	-- Pisó si la fase cruzó media vuelta (no al volver a cero cuando termina).
	local stepped = math.floor(gait / math.pi) ~= math.floor(s.gait / math.pi)
		and math.abs(gait - s.gait) < math.pi
	s.spin, s.flip, s.dy, s.gait = spin, flip, dy, gait
	pose.tailLift = (pose.tailLift or 0) + math.clamp(-0.3 * rise + 0.04 * flipRate, -0.8, 0.8)
	-- Topes: varias capas juntas (gusto, mirada, festejo) no doblan las orejas ni
	-- enroscan las colas.
	local ears = math.clamp(0.25 * rise, -0.5, 0.5)
	pose.earL = math.clamp((pose.earL or 0) - ears, -0.9, 0.9)
	pose.earR = math.clamp((pose.earR or 0) - ears, -0.9, 0.9)
	pose.tailWag = math.min(pose.tailWag or 0, 1.6)
	pose.tailGusto = math.clamp(pose.tailGusto or 0, 0, 1)
	for _, key in EMOTIONS do
		local value = pose[key]
		if value then
			pose[key] = math.clamp(value, 0, 1)
		end
	end
	pose.earTipL = math.clamp(pose.earTipL or 0, -1, 1)
	pose.earTipR = math.clamp(pose.earTipR or 0, -1, 1)
	-- Mientras hace lo suyo (take) la Mirada no lo tira hacia el jugador.
	pose.lookHold = math.clamp(math.max(pose.lookHold or 0, pose.take or 0), 0, 1)
	local out: Body = {
		take = math.clamp(pose.take or 0, 0, 1),
		spin = spin,
		flip = flip,
		runX = pose.runX or 0,
		runZ = pose.runZ or 0,
		turn = math.clamp(spinRate * 0.4, -2.5, 2.5),
		stepped = stepped,
		trail = math.clamp(pose.trail or 0, 0, 1),
		look = look,
		from = from,
		morsel = math.clamp(pose.morsel or 0, 0, 1),
		fed = fed,
	}
	return out
end

return table.freeze(Cuerpo)
