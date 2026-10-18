--!strict
--[[
	Zorro/Mirada

	Hacia dónde mira la cabeza. Corre antes de Pose.apply y suma a la pose:
		- los gestos: pasa las emo* por Cara/Gestos (suavizadas, ~0.2 s) y suma lo
		  que piden a orejas, mandíbula y ladeo (Cara escribe después la cara);
		- la mirada: lookYaw / lookPitch hacia el jugador de este cliente
		  (ctx.lookAt) cuando está en el cráter y dentro del cono de delante. Fija la
		  vista y solo la corre cuando el jugador se aleja más de DEAD rad de donde
		  mira (no persigue cada paso); llega con un resorte. Si queda de costado lo
		  mira de reojo (tope YAW_MAX); si queda detrás, lo suelta. Cada tanto mira
		  otra cosa (el agua, el cielo, su cola: Mirada/Episodios).
	Mientras mira, la mirada ocupa el lugar del mirar alrededor del reposo (queda
	KEEP de lo que traía la pose). lookHold (0..1) de la conducta la apaga: con 1
	solo cuenta el lookYaw/lookPitch que ya traía la pose. Topes (lo medido limpio,
	CONTRATO_OLA3 5): solo topa lo que suma, no lo que pidió la conducta.
	Es cosmético y local: cada cliente ve que lo mira a él.
		new()                 la memoria de una mirada (una por zorro)
		add(pose, ctx, memo?) sin memo usa una compartida (hay un solo zorro)
]]

local WorldLayout = require(script.Parent.Parent.WorldLayout)
local Episodios = require(script.Episodios)
local Gestos = require(script.Parent.Cara.Gestos)
local Resorte = require(script.Parent.Parent.Resorte)
local Tipos = require(script.Parent.Tipos)

export type Pose = { [string]: number }
export type Memo = {
	gestos: Gestos.Memo,
	episodio: Episodios.Episodio,
	fix: Vector2?, -- dónde fijó la vista en el jugador: (rumbo en el mundo, cabeceo)
	fixAt: number,
	seen: boolean, -- el jugador estaba a la vista el cuadro anterior
	weight: number, -- 0..1: cuánto manda la mirada (suave)
	attend: number, -- 0..1: cuánto mira al jugador (suave: la oreja de su lado)
	tilt: number, -- ladeo curioso (suave)
	yaw: Resorte.Resorte,
	pitch: Resorte.Resorte,
}

local TAU = math.pi * 2
local CRATER = Vector3.new(WorldLayout.craterCenter[1], 0, WorldLayout.craterCenter[2])
local NEAR, FAR = WorldLayout.craterRimOuter, WorldLayout.craterRimOuter + 70 -- studs del centro
local HEAD_UP, HEAD_FWD = 0.62, 0.37 -- dónde está la cabeza (fracción del alto)
local CONE_FULL, CONE_ZERO = 1.5, 2.3 -- rad: lo sigue de lleno / ya no lo sigue (detrás)
local YAW_MAX = 1.1 -- rad: de reojo
local PITCH_LO, PITCH_HI = -0.6, 0.45 -- rad hacia el jugador
local DEAD = 0.14 -- rad: corre la vista solo si el jugador se fue más que esto
local SETTLE, SETTLE_AT = 0.04, 2.5 -- o el ajuste fino, si pasaron SETTLE_AT s
local KEEP = 0.3 -- parte del mirar alrededor que queda mientras mira
local OTHER = 0.85 -- cuánto manda la mirada al agua, al cielo o a la cola
local WEIGHT_TIME = 0.45 -- s: entra y sale suave
local EAR = 0.15 -- para más la oreja del lado del jugador
local YAW_LIMIT, PITCH_DOWN, PITCH_UP = 1.6, -0.8, 1.1 -- topes medidos del cuello y la cabeza
-- Resorte de la cabeza por etapa: la cría mira rápido; la forma final, lenta y con peso.
local HZ = { 1.3, 1.1, 0.9, 0.7 }

local Mirada = {}

function Mirada.new(): Memo
	return {
		gestos = {},
		episodio = Episodios.new(),
		fix = nil,
		fixAt = 0,
		seen = false,
		weight = 0,
		attend = 0,
		tilt = 0,
		yaw = Resorte.new(),
		pitch = Resorte.new(),
	}
end

local shared: Memo? = nil

local function wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end

-- Hacia dónde está el jugador: (rumbo en el mundo, cabeceo, cuánto cuenta 0..1).
local function player(ctx: Tipos.Contexto): (number, number, number)
	local at = ctx.lookAt
	if not at then
		return 0, 0, 0
	end
	local fromCrater = Vector3.new(at.X, 0, at.Z) - CRATER
	local near = 1 - math.clamp((fromCrater.Magnitude - NEAR) / (FAR - NEAR), 0, 1)
	local forward = Vector3.new(-math.sin(ctx.heading), 0, -math.cos(ctx.heading))
	local head = ctx.center
		+ Vector3.new(0, HEAD_UP * ctx.height, 0)
		+ forward * HEAD_FWD * ctx.height
	local d = at - head
	local flat = Vector3.new(d.X, 0, d.Z).Magnitude
	if flat < 1 then
		return 0, 0, 0
	end
	local bearing = math.atan2(-d.X, -d.Z)
	local rel = math.abs(wrap(bearing - ctx.heading))
	local cone = 1 - math.clamp((rel - CONE_FULL) / (CONE_ZERO - CONE_FULL), 0, 1)
	return bearing, math.atan2(d.Y, flat), near * cone
end

-- Fija la vista en el jugador y la corre solo si se fue lejos: (giro, cabeceo).
local function aim(m: Memo, bearing: number, elev: number, ctx: Tipos.Contexto): (number, number)
	local fix = m.fix
	local off = if fix
		then math.max(math.abs(wrap(bearing - fix.X)), math.abs(elev - fix.Y))
		else math.huge
	if not fix or off > DEAD or (off > SETTLE and ctx.now - m.fixAt > SETTLE_AT) then
		fix = Vector2.new(bearing, elev)
		m.fix, m.fixAt = fix, ctx.now
	end
	return math.clamp(wrap(fix.X - ctx.heading), -YAW_MAX, YAW_MAX),
		math.clamp(fix.Y, PITCH_LO, PITCH_HI)
end

-- Suma a la pose sin pasar los topes; si la pose ya los pasaba, no la empeora.
local function blend(pose: Pose, key: string, value: number, w: number, lo: number, hi: number)
	local base = pose[key] or 0
	local out = base * (1 - w * (1 - KEEP)) + w * value
	pose[key] = math.clamp(out, math.min(lo, base), math.max(hi, base))
end

function Mirada.add(pose: Pose, ctx: Tipos.Contexto, memo: Memo?)
	local m = memo or shared or Mirada.new()
	if not memo then
		shared = m
	end
	local dt = ctx.dt
	Gestos.smooth(m.gestos, pose, dt)
	Gestos.add(pose)

	local e = m.episodio
	local bearing, elev, sight = player(ctx)
	local visible = sight > 0.3
	-- Lo acaba de ver: corta lo que miraba para mirarlo a él.
	if ctx.now >= e.ends or (visible and not m.seen and e.mode ~= "jugador") then
		Episodios.next(e, ctx.now, visible)
	end
	m.seen = visible

	local yaw, pitch, want = 0, 0, 0
	if e.mode == "jugador" then
		if sight > 0 then
			yaw, pitch = aim(m, bearing, elev, ctx)
			want = sight
		end
	else
		m.fix = nil
		if e.mode ~= "libre" then
			yaw, pitch, want = e.other.X, e.other.Y, OTHER
		end
	end
	want *= 1 - math.clamp(pose.lookHold or 0, 0, 1)
	local k = 1 - math.exp(-dt / WEIGHT_TIME)
	local attending = if e.mode == "jugador" then want else 0
	m.weight += (want - m.weight) * k
	m.attend += (attending - m.attend) * k
	m.tilt += (e.tilt * attending - m.tilt) * k
	local hz = HZ[math.clamp(ctx.etapa, 1, #HZ)]
	local sYaw = Resorte.step(m.yaw, yaw, dt, hz, 1)
	local sPitch = Resorte.step(m.pitch, pitch, dt, hz, 1)

	if m.weight < 1e-3 then
		return
	end
	blend(pose, "lookYaw", sYaw, m.weight, -YAW_LIMIT, YAW_LIMIT)
	blend(pose, "lookPitch", sPitch, m.weight, PITCH_DOWN, PITCH_UP)
	-- Mirando al jugador: ladea la cabeza curioso y para más la oreja de su lado.
	pose.tilt = (pose.tilt or 0) + m.tilt
	local left = 0.675 + 0.325 * math.clamp(sYaw * 3, -1, 1) -- 1 si está a su izquierda
	pose.earL = (pose.earL or 0) + EAR * m.attend * left
	pose.earR = (pose.earR or 0) + EAR * m.attend * (1.35 - left)
end

return table.freeze(Mirada)
