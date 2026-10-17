--!strict
--[[
	Dragon/Destino

	Adónde va el dragón este cuadro y cómo llega (Rumbo):
		- su vuelta sobre la lava (Vuelo), con lo que le sume el truco (dy sube o
		  baja, speed acelera o frena);
		- frente a la orilla de quien le da de comer (cuanto más come, w, más
		  manda), a la altura del borde del cráter;
		- quieto donde estaba si evoluciona en el aire (frozen);
		- donde diga la rutina si sigue una posada (pin: Dragon/Conducta).
	Si despega solo (lo cortaron posado), el salto le da la velocidad de golpe.
]]

local WorldLayout = require(script.Parent.Parent.WorldLayout)
local Conducta = require(script.Parent.Conducta)
local Etapas = require(script.Parent.Etapas)
local Rumbo = require(script.Parent.Rumbo)
local Vuelo = require(script.Parent.Vuelo)

local JUMP = 0.9 -- velocidad del salto: fracción de la de crucero

export type Ctx = {
	now: number,
	route: Vuelo.Route,
	Lpath: number,
	direction: Vector3?, -- hacia quien le da de comer (desde el centro)
	feeding: number, -- w, 0..1
	frozen: Vector3?,
	pose: { [string]: number },
	doing: Conducta.Out,
	profile: Etapas.Profile,
}

local Destino = {}

function Destino.steer(r: Rumbo.Rumbo, dt: number, c: Ctx)
	local p, route = c.pose, c.route
	local loop = Vuelo.sample(c.now, route)
	local goal, flow = loop.position + Vector3.new(0, p.dy or 0, 0), loop.velocity * (p.speed or 1)
	local direction = c.direction
	if direction then
		local standoff = WorldLayout.craterCliffRadius - 12 - c.Lpath * 0.45
		local hoverAt = route.center
			+ direction * math.max(standoff, 20)
			+ Vector3.new(0, WorldLayout.craterRimHeight + 4 + c.Lpath * 0.22, 0)
		goal = goal:Lerp(hoverAt, c.feeding)
	end
	if c.frozen then
		goal, flow = c.frozen, Vector3.zero
	end
	local doing = c.doing
	Rumbo.update(r, dt, {
		goal = goal,
		flow = flow,
		feeding = c.feeding,
		face = direction,
		facing = doing.facing,
		bank = c.profile.bank,
		pitch = p.pitch or 0,
		roll = p.roll,
		pin = doing.pin,
		pinVelocity = doing.pinVelocity,
		pinW = doing.pinW,
	})
	if doing.jump then
		local out = Vector3.new(-math.sin(r.yaw), 0, -math.cos(r.yaw))
		r.velocity = (out * 0.35 + Vector3.yAxis) * route.speed * JUMP
	end
end

return table.freeze(Destino)
