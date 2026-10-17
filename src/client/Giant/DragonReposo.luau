--!strict
--[[
	DragonReposo

	Si el dragón vuela, está posado en su roca o duerme, contado por sus
	eventos (land → posado, takeoff → vuela, sleep → duerme, wake → posado):
	así no depende de los campos internos del comportamiento. Si "posado" se
	mueve rápido un rato es que ya vuela (por si se perdió el takeoff).
	Cada tanto, en calma, devuelve un momento propio:
		growl   volando: un gruñido o chillido suelto (cada 16-28 s)
		idle    posado: resopla humo por la nariz y gruñe bajito (cada 6-11 s)
		snore   dormido: hilos de humo al respirar (cada 3.5-5.5 s)
]]

export type Mode = "air" | "perch" | "sleep"
export type Reposo = { mode: Mode, calm: number, nextAt: number, moving: number }

local EVERY: { [Mode]: NumberRange } = {
	air = NumberRange.new(16, 28),
	perch = NumberRange.new(6, 11),
	sleep = NumberRange.new(3.5, 5.5),
}
local KIND: { [Mode]: string } = { air = "growl", perch = "idle", sleep = "snore" }
local MODE_BY_EVENT: { [string]: Mode } = {
	land = "perch",
	takeoff = "air",
	sleep = "sleep",
	wake = "perch",
}
local MOVING_SPEED = 14 -- studs/s
local MOVING_SECONDS = 1.5

local DragonReposo = {}

local rng = Random.new()

local function pause(mode: Mode): number
	local range = EVERY[mode]
	return rng:NextNumber(range.Min, range.Max)
end

function DragonReposo.new(): Reposo
	return { mode = "air", calm = 0, nextAt = pause("air"), moving = 0 }
end

local function setMode(r: Reposo, mode: Mode)
	if r.mode ~= mode then
		r.mode = mode
		r.nextAt = pause(mode)
	end
end

-- Un evento del dragón: cambia el modo y reinicia la calma (los propios no).
function DragonReposo.event(r: Reposo, kind: string)
	local mode = MODE_BY_EVENT[kind]
	if mode then
		setMode(r, mode)
	end
	if kind ~= "flap" and kind ~= "hover" then
		r.calm = 0
	end
end

-- El momento propio que toca ahora (o nil).
function DragonReposo.step(r: Reposo, dt: number, speed: number): string?
	if r.mode ~= "air" and speed > MOVING_SPEED then
		r.moving += dt
		if r.moving > MOVING_SECONDS then
			setMode(r, "air")
		end
	else
		r.moving = 0
	end
	r.calm += dt
	if r.calm < r.nextAt then
		return nil
	end
	r.calm, r.nextAt = 0, pause(r.mode)
	return KIND[r.mode]
end

return table.freeze(DragonReposo)
