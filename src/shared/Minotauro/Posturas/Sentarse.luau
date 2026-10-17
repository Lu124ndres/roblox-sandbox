--!strict
--[[
	Sentarse: mira el suelo y se agacha (anticipación), se deja caer con peso
	(acelera hasta el golpe: la cadera se echa atrás, las piernas salen hacia
	adelante y el cuerpo baja de verdad, ~20 % del alto), se aplasta con el golpe
	y rebota un poco. Sentado hace dos cosas (Posturas/Sentado: rascarse, bostezar,
	mirar o dormitar) y para pararse recoge las piernas inclinándose adelante y se
	impulsa, estirándose al terminar. Cuánto baja lo calcula Cuerpo.plant con las
	pezuñas: sentado se apoya en los talones, la cola del cuerpo queda a ~1 celda
	del suelo y la borla de la cola apoyada atrás (tailCurl). Los faldones de los
	costados se abren sobre el suelo y el de adelante sube hasta body.seatSkirt.
	Las posturas clave se revisaron en Blender en las cuatro etapas.
	Si lo interrumpen sentado (darle de comer manda), leave se para enseguida.
]]

local Azar = require(script.Parent.Parent.Azar)
local C = require(script.Parent.Parent.Trucos.Curvas)
local Cuerpo = require(script.Parent.Parent.Cuerpo)
local Pose = require(script.Parent.Parent.Pose)
local Sentado = require(script.Parent.Sentado)
local Tipos = require(script.Parent.Tipos)

local CROUCH = 0.05 -- se agacha (anticipación) hasta aquí
local LAND = 0.085 -- el golpe al caer sentado
local GATHER = 0.82 -- recoge las piernas para pararse
local PUSH = 0.88 -- se impulsa
local UP = 0.95 -- ya está parado
local WINDOWS = { { 0.16, 0.47 }, { 0.51, 0.8 } } -- lo que hace sentado
local LEAVE_SECONDS = 1.5
local LEAVE_PUSH = 0.45

local SQUAT_DOWN: Pose.Pose = {
	legL = 0.7,
	legR = 0.7,
	kneeL = 1.3,
	kneeR = 1.3,
	lean = -0.15,
	lookPitch = -0.2,
	armL = 0.7,
	armR = 0.7,
	elbowL = 0.3,
	elbowR = 0.3,
	outL = 0.2,
	outR = 0.2,
	tailUp = 0.3,
}
local SEATED: Pose.Pose = {
	hip = 0.5,
	legL = 0.9,
	legR = 0.9,
	footL = 0.3,
	footR = 0.3,
	lean = -0.2,
	armL = 0.9,
	armR = 0.9,
	elbowL = 0.9,
	elbowR = 0.9,
	outL = 0.25,
	outR = 0.25,
	faldonL = 1.1,
	faldonR = 1.1,
	tailUp = 0.5,
	tailCurl = 1.1,
	tail2 = 0.3,
	tail3 = 0.4,
}
local SQUAT_UP: Pose.Pose = {
	legL = 1,
	legR = 1,
	kneeL = 1.6,
	kneeR = 1.6,
	lean = -0.3,
	lookPitch = 0.1,
	armL = 1,
	armR = 1,
	elbowL = 0.4,
	elbowR = 0.4,
	outL = 0.3,
	outR = 0.3,
	tailUp = 0.4,
}

local function mix(a: Pose.Pose?, b: Pose.Pose?, t: number): Pose.Pose
	local out = {}
	if a then
		Pose.add(out, a, 1 - t)
	end
	if b then
		Pose.add(out, b, t)
	end
	return out
end

local function seated(): Pose.Pose
	return table.clone(SEATED)
end

-- Al terminar de pararse se estira: pecho afuera, cabeza arriba, brazos abiertos.
local function stretch(t: number): Pose.Pose
	local b = C.bell(t)
	return { lean = 0.12 * b, lookPitch = 0.1 * b, outL = 0.25 * b, outR = 0.25 * b }
end

-- La postura sin lo que hace sentado, para el avance u, y cuánto está sentado (0..1).
local function shape(u: number): (Pose.Pose, number)
	if u < CROUCH then
		return mix(nil, SQUAT_DOWN, C.smooth(u / CROUCH)), 0
	elseif u < LAND then
		local t = C.span(u, CROUCH, LAND)
		t *= t -- cae: acelera hasta el golpe
		return mix(SQUAT_DOWN, seated(), t), t
	elseif u < GATHER then
		local pose = seated()
		local hit = C.decay(u, LAND, 60)
		Pose.add(
			pose,
			{ lean = -0.2 * hit, lookPitch = -0.1 * hit, armL = 0.2 * hit, armR = 0.2 * hit }
		)
		pose.dy = 0.01 * C.bell(C.span(u, LAND, LAND + 0.025)) -- rebota
		return pose, 1
	elseif u < PUSH then
		local t = C.smooth(C.span(u, GATHER, PUSH))
		return mix(seated(), SQUAT_UP, t), 1 - t
	end
	local t = C.span(u, PUSH, UP)
	local pose = mix(SQUAT_UP, nil, C.smooth(t))
	Pose.add(pose, stretch(C.span(u, PUSH + 0.02, 1)))
	return pose, 0
end

-- Sentado, las pezuñas empujan el faldón de adelante más que lo que pide el muslo
-- (Cuerpo.skirt): se levanta hasta body.seatSkirt, en proporción a lo sentado.
local function base(u: number, ctx: Tipos.Ctx): (Pose.Pose, number)
	local pose, sat = shape(u)
	local body = ctx.profile.body
	local extra = math.max(0, math.rad(body.seatSkirt) - Cuerpo.skirt(pose, body))
	pose.faldonF = (pose.faldonF or 0) + extra * sat
	return pose, sat
end

local function activities(ctx: Tipos.Ctx): { string }
	local names = Sentado.names(ctx.profile.rutina.siesta)
	local first = Azar.pick(#names, ctx.seed, 1)
	local second = (first + Azar.pick(#names - 1, ctx.seed, 2) - 1) % #names + 1 -- otra distinta
	return { names[first], names[second] }
end

local function pose(u: number, ctx: Tipos.Ctx): Pose.Pose
	local result, sat = base(u, ctx)
	for i, name in activities(ctx) do
		local window = WINDOWS[i]
		local v = C.span(u, window[1], window[2])
		if v > 0 and v < 1 then
			Pose.add(result, Sentado.get(name).pose(v), sat)
		end
	end
	return result
end

return table.freeze({
	name = "sentarse",
	seconds = 14,
	events = function(ctx: Tipos.Ctx): { Tipos.Event }
		local list = { { at = LAND, kind = "sit" }, { at = PUSH, kind = "standup" } }
		for i, name in activities(ctx) do
			local event = Sentado.get(name).event
			if event then
				local window = WINDOWS[i]
				table.insert(
					list,
					{ at = window[1] + event.at * (window[2] - window[1]), kind = event.kind }
				)
			end
		end
		return list
	end,
	pose = pose,
	leave = function(from: number, ctx: Tipos.Ctx): Tipos.Leave?
		local frozen, sat = base(from, ctx)
		if sat < 0.05 then
			return nil -- todavía (o ya) de pie: se desvanece
		end
		frozen = pose(from, ctx)
		return {
			seconds = LEAVE_SECONDS,
			events = { { at = LEAVE_PUSH, kind = "standup" } },
			pose = function(k: number): Pose.Pose
				if k < LEAVE_PUSH then
					return mix(frozen, SQUAT_UP, C.smooth(k / LEAVE_PUSH))
				end
				local t = C.span(k, LEAVE_PUSH, 1)
				local out = mix(SQUAT_UP, nil, C.smooth(t))
				Pose.add(out, stretch(t))
				return out
			end,
		}
	end,
} :: Tipos.Behavior)
