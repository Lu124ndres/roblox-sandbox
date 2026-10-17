--!strict
--[[
	Dragon/Apoyo

	Pone el cuerpo del dragón cada cuadro: orientación, pose de los huesos y,
	cerca de una roca, las patas sobre la cima.
		ground(a, target, dt)  cuánto está de pie (0..1), suavizado: al tocar la
		                cabeza y el cuerpo pasan del vuelo a la pose posada sin saltos
		place(...)      cabeceo y alabeo: los del vuelo (Rumbo) o, de pie, el que
		                nivela las patas (Posado.balance) más el de la pose; pasa la
		                pose a los huesos (Pose.apply) y, sobre la roca, sube la raíz
		                hasta que la garra más baja apoya en la cima (Posado.clearance;
		                hop la levanta en un brinco). Lo que sube lo guarda en Rumbo,
		                así al soltarlo para despegar no cae
		tail(...)       la cola no atraviesa la roca (Posado.tail)
]]

local Cuerpo = require(script.Parent.Cuerpo)
local Etapas = require(script.Parent.Etapas)
local Guarida = require(script.Parent.Guarida)
local Pose = require(script.Parent.Pose)
local Posado = require(script.Parent.Posado)
local Rig = require(script.Parent.Rig)
local Rumbo = require(script.Parent.Rumbo)
local Rutina = require(script.Parent.Rutina)

local NEAR = 0.6 -- largos del dragón fuera de la cima en que todavía apoya

export type Apoyo = { ground: number, balance: Posado.Balance }
export type Ctx = {
	now: number,
	dt: number,
	L: number,
	ground: number,
	profile: Etapas.Profile,
	wings: Cuerpo.Wings,
}

local Apoyo = {}

function Apoyo.new(): Apoyo
	return { ground = -1, balance = { level = 0.3, bend = 0 } } -- -1: todavía no lo vio
end

function Apoyo.ground(a: Apoyo, target: number, dt: number): number
	a.ground = if a.ground < 0
		then target
		else a.ground + (target - a.ground) * (1 - math.exp(-dt * 10))
	return a.ground
end

function Apoyo.place(
	a: Apoyo,
	rig: Rig.Rig?,
	r: Rumbo.Rumbo,
	line: Rutina.Timeline?,
	p: Pose.Pose,
	ctx: Ctx
): CFrame
	local g = ctx.ground
	local pitch = r.pitch * (1 - g) + (a.balance.level + (p.pitch or 0)) * g
	local rot = CFrame.Angles(0, r.yaw, 0)
		* CFrame.Angles(pitch, 0, 0)
		* CFrame.Angles(0, 0, r.roll * (1 - g))
	local position = r.position :: Vector3
	if not rig then
		return CFrame.new(position) * rot
	end
	p.bend = (p.bend or 0) + a.balance.bend * g
	local wings = ctx.wings
	Pose.apply(rig, {
		profile = ctx.profile,
		now = ctx.now,
		phase = wings.phase,
		amp = wings.amp,
		fold = wings.fold,
		turn = r.yawRate,
		climb = r.climb,
		hover = wings.hover,
		pitch = pitch,
	}, p, ctx.dt)
	if line then
		local perch = Guarida.perches[line.perch]
		local away = Vector3.new(position.X - line.top.X, 0, position.Z - line.top.Z).Magnitude
		if away < perch.size + ctx.L * NEAR then
			local floor = line.top.Y + Posado.clearance(rig, rot) + (p.hop or 0) * ctx.L
			if position.Y < floor then
				position = Vector3.new(position.X, floor, position.Z)
				r.position = position
				r.velocity = Vector3.new(r.velocity.X, math.max(r.velocity.Y, 0), r.velocity.Z)
			end
		end
		if g > 0.5 then
			Posado.balance(a.balance, rig, rot)
		end
	end
	return CFrame.new(position) * rot
end

function Apoyo.tail(rig: Rig.Rig, pivot: CFrame, line: Rutina.Timeline)
	local perch = Guarida.perches[line.perch]
	Posado.tail(rig, pivot, function(point: Vector3): number
		return Posado.surface(perch, point)
	end)
end

return table.freeze(Apoyo)
