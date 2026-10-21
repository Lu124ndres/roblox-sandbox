--!strict
--[[
	OrcaMotion/Apunte

	Hacia dónde queda la rampa para los trucos de lucirse (Schedule.Aim): cuánto
	giraría la orca a una hora dada para mirar la puerta del cráter (Path.door),
	desde el rumbo de su recorrido o desde el suyo de ahora, y el fondo bajo el
	recorrido (los trucos hondos lo piden). Las funciones se arman una vez por
	orca; step solo cambia lo de cada cuadro (Schedule llama a `at` y `floor` una
	vez por tramo).
]]

local Perfil = require(script.Parent.Parent.Etapas.Perfil)
local Path = require(script.Parent.Path)
local Schedule = require(script.Parent.Schedule)
local Steer = require(script.Parent.Steer)
local Tricks = require(script.Parent.Tricks)

local MOVING = 0.5 -- studs/s: más lento flota quieta y no tiene rumbo propio

export type Apunte = {
	aim: Schedule.Aim,
	radius: number,
	height: number,
	breath: Perfil.Breath?,
}

local Apunte = {}

-- Cuánto tendría que girar desde `yaw` para mirar la rampa desde `position` (+ = izq.).
local function turnTo(position: Vector3, yaw: number): number
	local to = Path.door() - position
	return if to.Magnitude < 1 then 0 else Tricks.wrap(Steer.yawOf(to) - yaw)
end

function Apunte.new(): Apunte
	local self: Apunte
	local function at(t: number): Path.Sample?
		local breath = self.breath
		return if breath then Path.sample(t, self.radius, 0, breath) else nil
	end
	self = {
		radius = 1,
		height = 1,
		breath = nil,
		aim = {
			now = 0,
			at = function(t: number): number
				local s = at(t)
				if not s or s.velocity.Magnitude <= MOVING then
					return 0
				end
				return turnTo(s.position, Steer.yawOf(s.velocity))
			end,
			floor = function(t: number): number
				local s = at(t)
				return if s then Path.floor(s.position.Magnitude) / self.height else -1
			end,
		},
	}
	return self
end

function Apunte.step(
	apunte: Apunte,
	radius: number,
	height: number,
	profile: Perfil.Profile,
	steer: Steer.Steer?
): Schedule.Aim
	apunte.radius, apunte.height, apunte.breath = radius, height, profile.breath
	apunte.aim.now = if steer then turnTo(steer.position, steer.yaw) else 0
	return apunte.aim
end

return table.freeze(Apunte)
