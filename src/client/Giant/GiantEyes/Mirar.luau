--!strict
--[[
	GiantEyes/Mirar

	Hacia dónde se corre cada pupila, como fracción de su recorrido (-1..1 en el
	ancho y el alto del ojo). Imita la mirada de la cabeza del zorro (Zorro/Mirada):
		- fija la vista en un punto del jugador y la corre solo cuando él se
		  aleja más de DeadAngle de ese punto (o SettleAngle, si pasó
		  SettleSeconds): no persigue cada paso;
		- en el plano de cada ojo, la pupila va hacia el punto fijado; llega al
		  tope a MaxAngle del frente del ojo y, si el punto queda detrás
		  (ConeFull..ConeZero), vuelve al centro;
		- encima, los detalles de vida: saltitos de la vista (un hash del tramo
		  de tiempo, sin estado) y una deriva lenta (math.noise). Los dos ojos
		  saltan juntos;
		- un resorte por eje lleva la pupila adonde va.
	Sin objetivo, solo quedan los detalles de vida alrededor del centro.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resorte = require(ReplicatedStorage.Shared.Resorte)
local Settings = require(ReplicatedStorage.Shared.UIConfig.GiantEyes)

type Springs = { x: Resorte.Resorte, y: Resorte.Resorte }

export type Memo = {
	seed: number, -- cada gigante salta a su ritmo
	fix: Vector3?, -- dónde fijó la vista
	fixAt: number,
	springs: { Springs },
	out: { Vector2 }, -- reusada: el corrimiento de cada pupila
}

local Mirar = {}

-- Un número de -1 a 1 que solo depende de n y salt (sin estado ni math.random).
local function hash(n: number, salt: number): number
	local s = math.sin(n * 12.9898 + salt * 78.233) * 43758.5453
	return (s - math.floor(s)) * 2 - 1
end

local function angleBetween(a: Vector3, b: Vector3): number
	if a.Magnitude < 1e-6 or b.Magnitude < 1e-6 then
		return 0
	end
	return math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1))
end

function Mirar.new(seed: number): Memo
	return { seed = seed, fix = nil, fixAt = 0, springs = {}, out = {} }
end

-- Saltitos y deriva, compartidos por los dos ojos.
local function life(seed: number, now: number): Vector2
	local bucket = math.floor(now / Settings.MicroSeconds + seed)
	local jump = Vector2.new(hash(bucket, seed + 1), hash(bucket, seed + 2)) * Settings.MicroAmount
	local t = now * Settings.DriftHz
	local drift = Vector2.new(math.noise(t, seed + 0.5, 0.25), math.noise(seed + 0.5, t, 0.75))
		* (2 * Settings.DriftAmount) -- math.noise casi siempre queda en -0.5..0.5
	return jump + drift
end

-- Corrimiento de una pupila hacia el punto, en el plano de su ojo.
local function aim(eye: CFrame, at: Vector3): Vector2
	local p = eye:PointToObjectSpace(at) -- el ojo mira a -Z
	local lateral = Vector2.new(p.X, p.Y)
	local side = lateral.Magnitude
	if side < 1e-6 then
		return Vector2.zero -- justo al frente
	end
	local angle = math.atan2(side, -p.Z) -- 0 al frente, pi detrás
	local cone = 1
		- math.clamp(
			(angle - Settings.ConeFull) / math.max(Settings.ConeZero - Settings.ConeFull, 1e-3),
			0,
			1
		)
	return lateral.Unit * (math.min(angle / Settings.MaxAngle, 1) * cone)
end

-- Fija la vista en el objetivo, o la deja donde estaba si se movió poco.
local function refix(m: Memo, head: Vector3, target: Vector3?, now: number)
	if not target then
		m.fix = nil
		return
	end
	local fix = m.fix
	local off = if fix then angleBetween(target - head, fix - head) else math.huge
	if
		not fix
		or off > Settings.DeadAngle
		or (off > Settings.SettleAngle and now - m.fixAt > Settings.SettleSeconds)
	then
		m.fix, m.fixAt = target, now
	end
end

-- eyes: dónde están los ojos; target: el jugador (o nil). Devuelve m.out.
function Mirar.step(
	m: Memo,
	eyes: { CFrame },
	target: Vector3?,
	dt: number,
	now: number
): { Vector2 }
	local head = Vector3.zero
	for _, eye in eyes do
		head += eye.Position
	end
	head /= math.max(#eyes, 1)
	refix(m, head, target, now)
	local fix = m.fix
	local extra = life(m.seed, now)
	for i, eye in eyes do
		local want = (if fix then aim(eye, fix) else Vector2.zero) + extra
		if want.Magnitude > 1 then
			want = want.Unit
		end
		local s = m.springs[i]
		if not s then
			s = { x = Resorte.new(), y = Resorte.new() }
			m.springs[i] = s
		end
		local hz, damping = Settings.SpringHz, Settings.SpringDamping
		local shift = Vector2.new(
			Resorte.step(s.x, want.X, dt, hz, damping),
			Resorte.step(s.y, want.Y, dt, hz, damping)
		)
		m.out[i] = if shift.Magnitude > 1 then shift.Unit else shift -- el rebote no sale del ojo
	end
	for i = #eyes + 1, #m.out do
		m.out[i] = nil
	end
	return m.out
end

return table.freeze(Mirar)
