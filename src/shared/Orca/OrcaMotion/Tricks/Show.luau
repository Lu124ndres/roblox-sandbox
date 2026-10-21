--!strict
--[[
	OrcaMotion/Tricks/Show

	Trucos para lucirse frente a los jugadores:
		spyhop  asomarse (spyhop) como las orcas de verdad: se para vertical
		        bajo el agua, sube despacio hasta sacar la cabeza (`height`:
		        altura del hocico sobre el agua, en altos), sopla, se sostiene
		        aleteando con las pectorales y gira despacio mirando alrededor
		        (`looks` miradas) de cara a la rampa; después se hunde derecha y
		        se acuesta. Con `stare` (la anciana) no mira a los lados: baja
		        la cabeza hacia la rampa y la mira fija con la boca entreabierta.
		roar    levanta la cabeza, abre la boca enorme y ruge; el cuerpo tiembla.
		emerge  baja al fondo y sube despacio hasta quedar muy por encima del
		        agua, como una isla, con el agua cayéndole del lomo; luego se
		        vuelve a hundir.
]]

local Respirar = require(script.Parent.Respirar)
local Tricks = require(script.Parent)

local smooth, span, bell, lerp = Tricks.smooth, Tricks.span, Tricks.bell, Tricks.lerp

export type Style = {
	talla: Tricks.Talla?,
	pitch: number?, -- qué tan parada (rad); la anciana no cabe vertical en el lago
	stare: boolean?, -- mira fija a la rampa
	sub: number?, -- cuánto más abajo se para antes de asomar (altos)
}

local STAND = 1.4 -- rad (~80°): casi vertical
local SUB = 0.25 -- antes de asomar se para bajo el agua, esto más abajo (altos)
local A, B, C, D = 0.16, 0.34, 0.76, 0.88 -- se para, asoma, se queda, se hunde, se acuesta
local LOOK = 0.55 -- cuánto gira a cada lado al mirar (rad)
local BOB, BOB_SECONDS = 0.015, 2.6 -- se mece arriba y abajo al sostenerse
local SCULL_SECONDS = 1.6 -- cada aletazo de las pectorales para sostenerse

local Show = {}

function Show.spyhop(height: number, looks: number, seconds: number, style: Style?): Tricks.Trick
	local s: Style = style or {}
	local talla = s.talla or Tricks.ADULTA
	local stand = s.pitch or STAND
	local stare = s.stare == true
	local top = height - talla.half * math.sin(stand) -- el centro con el hocico afuera
	local sub = s.sub or SUB
	local blowAt = (B + 0.03) * seconds
	return {
		name = "asomarse",
		seconds = seconds,
		events = { { at = B + 0.03, kind = "spout" }, { at = B + 0.1, kind = "call" } },
		vary = 0.15,
		show = (B + C) / 2,
		deep = sub - top + talla.half * math.sin(stand), -- la cola, parada
		pose = function(u: number, from: number, seed: number?): Tricks.Pose
			local t, phase = u * seconds, (seed or 0.5) * 6
			local up = smooth(span(u, 0, A)) * (1 - smooth(span(u, D, 1)))
			local out = smooth(span(u, A, B)) * (1 - smooth(span(u, C, D)))
			local look = if stare
				then 0
				else LOOK * math.sin(2 * math.pi * looks * span(u, B, C) + phase) * smooth(
					span(u, B, B + 0.08)
				)
			local scull = 2 * math.pi * t / (SCULL_SECONDS * talla.pace)
			local pose: Tricks.Pose = {
				depth = lerp(from, top - sub, up) + sub * out + BOB * math.sin(
					2 * math.pi * t / BOB_SECONDS
				) * out,
				pitch = stand * up,
				yaw = look * out,
				head = (if stare then -0.2 else 0.08) * out, -- la anciana mira abajo, a la rampa
				jaw = (if stare then 0.3 else 0.12) * out,
				fin = { -- se sostiene aleteando con las pectorales, cada una a su tiempo
					izq = (-0.35 + 0.18 * math.sin(scull)) * up,
					der = (-0.35 + 0.18 * math.sin(scull + 2.1)) * up,
				},
				fins = -0.3 * up,
				effort = lerp(1, 0.35, up),
				speed = lerp(1, 0.05, up),
				face = out,
			}
			return Respirar.add(pose, t - blowAt, talla.pace)
		end,
	}
end

function Show.roar(seconds: number): Tricks.Trick
	return {
		name = "rugido",
		seconds = seconds,
		events = { { at = 0.32, kind = "roar" }, { at = 0.85, kind = "spout" } },
		pose = function(u: number, from: number): Tricks.Pose
			local up = smooth(span(u, 0, 0.25)) * (1 - smooth(span(u, 0.8, 1)))
			local open = smooth(span(u, 0.22, 0.32)) * (1 - smooth(span(u, 0.68, 0.8)))
			local shake = math.sin(u * seconds * 38) * 0.05 * open
			return {
				depth = from + (0.12 - from) * up,
				pitch = 0.55 * up + shake,
				roll = shake,
				head = 0.25 * open,
				jaw = 1.15 * open,
				fins = -0.6 * up,
				effort = 0.4,
				speed = 0.15,
			}
		end,
	}
end

function Show.emerge(height: number, seconds: number): Tricks.Trick
	return {
		name = "emerger",
		seconds = seconds,
		events = {
			{ at = 0.5, kind = "cascade" },
			{ at = 0.62, kind = "spout" },
			{ at = 0.72, kind = "cascade" },
		},
		pose = function(u: number, from: number): Tricks.Pose
			local down = smooth(span(u, 0, 0.25))
			local up = smooth(span(u, 0.3, 0.6))
			local back = smooth(span(u, 0.8, 1))
			local level = from + (-0.9 - from) * down
			level += (height + 0.9) * up
			level += (from - height) * back
			return {
				depth = level,
				pitch = 0.2 * bell(span(u, 0.25, 0.65)) - 0.15 * bell(span(u, 0.8, 1)),
				effort = 0.6,
				speed = 0.3,
				fins = -0.3 * up * (1 - back),
				jaw = 0.2 * up * (1 - back),
			}
		end,
	}
end

return table.freeze(Show)
