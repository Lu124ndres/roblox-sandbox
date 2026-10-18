--!strict
--[[
	GuidePath

	La fila de flechas del tutorial: una línea recta de flechas amarillas
	flotando a la altura del pecho (GuideArrow) que sale del jugador y llega
	hasta el destino de la misión (pedido del usuario: «que lleguen hasta
	donde tienes que ir»), en tramos rectos (al volcán, primero a la entrada
	del puente y después por el puente hasta la puerta; lo decide
	TutorialGuide). Una onda suave las recorre hacia adelante; las más lejanas
	van un poco transparentes para no saturar. Al cambiar de tramo la línea
	gira suave. Todo solo en este cliente: no hay nada puesto en el mapa.
]]

local GuideArrow = require(script.Parent.GuideArrow)

local COUNT = 32 -- flechas como mucho (a 6 studs, ~190 studs: la isla entera)
local SPACING = 6 -- studs entre flecha y flecha
local FIRST = 5 -- la primera, así de adelante del jugador
local LAST = 6 -- la última, así de antes del destino
local HEIGHT = 0.3 -- respecto del centro del cuerpo: a la altura del pecho
local SCALE = 0.9
local WAVE = 0.35 -- alto de la onda que las recorre
local WAVE_SPEED = 5
local TURN = 5 -- qué tan rápido gira la fila hacia la dirección nueva (por segundo)
local NEAR = 8 -- las primeras flechas, opacas; de ahí se van aclarando
local FAR_SEE_THROUGH = 0.45 -- transparencia de las más lejanas

export type Path = {
	update: (position: Vector3, target: Vector3, t: number, dt: number) -> (),
	hide: () -> (),
}

local GuidePath = {}

function GuidePath.new(): Path
	local arrows: { GuideArrow.Shape } = {}
	for k = 1, COUNT do
		arrows[k] = GuideArrow.shape(GuideArrow.group(), `Camino{k}`, SCALE)
	end
	local heading: Vector3? = nil

	local function hideArrow(arrow: GuideArrow.Shape)
		for _, item in arrow do
			item.part.Transparency = 1
		end
	end

	local function hide()
		for _, arrow in arrows do
			hideArrow(arrow)
		end
		heading = nil
	end

	local function update(position: Vector3, target: Vector3, t: number, dt: number)
		local toTarget = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
		local distance = toTarget.Magnitude
		if distance < 1e-3 then
			hide()
			return
		end
		-- La fila gira suave hacia el destino (al pasar de un tramo al otro no salta).
		local wanted = toTarget.Unit
		local current = heading or wanted
		local turned = current:Lerp(wanted, math.clamp(dt * TURN, 0, 1))
		local forward = if turned.Magnitude > 1e-3 then turned.Unit else wanted
		heading = forward
		-- Sube o baja parejo con el terreno entre el jugador y el destino.
		local climb = (target.Y - position.Y) / distance
		for k, arrow in arrows do
			local along = FIRST + (k - 1) * SPACING
			if along > distance - LAST then
				hideArrow(arrow)
				continue
			end
			local wave = math.sin(t * WAVE_SPEED - k * 0.9) * WAVE
			local spot = position
				+ forward * along
				+ Vector3.new(0, HEIGHT + wave + climb * along, 0)
			local fade = FAR_SEE_THROUGH * math.clamp((k - NEAR) / (COUNT - NEAR), 0, 1)
			GuideArrow.pose(arrow, CFrame.lookAt(spot, spot + forward), fade)
		end
	end

	return { update = update, hide = hide }
end

return GuidePath
