--!strict
--[[
	GuidePath

	La fila de flechas del tutorial: una línea recta de flechas amarillas
	flotando a la altura del pecho (GuideArrow) que sale del jugador y apunta
	al destino de la misión (en tramos rectos: al volcán, primero a la entrada
	del puente y después por el puente; lo decide TutorialGuide). Siempre se
	ven todas, sin curvas ni desvanecerse; una onda suave las recorre hacia
	adelante para que se sienta el «por acá». Si el destino está más cerca que
	la fila, solo se ven las que caben. Al cambiar de tramo la línea gira
	suave. Todo solo en este cliente: no hay nada puesto en el mapa.
]]

local GuideArrow = require(script.Parent.GuideArrow)

local COUNT = 6 -- flechas en la fila
local SPACING = 6 -- studs entre flecha y flecha
local FIRST = 5 -- la primera, así de adelante del jugador
local HEIGHT = 0.3 -- respecto del centro del cuerpo: a la altura del pecho
local SCALE = 0.9
local WAVE = 0.35 -- alto de la onda que las recorre
local WAVE_SPEED = 5
local TURN = 5 -- qué tan rápido gira la fila hacia la dirección nueva (por segundo)

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
		for k, arrow in arrows do
			local along = FIRST + (k - 1) * SPACING
			if along > distance then
				hideArrow(arrow)
				continue
			end
			local wave = math.sin(t * WAVE_SPEED - k * 0.9) * WAVE
			local spot = position + forward * along + Vector3.new(0, HEIGHT + wave, 0)
			GuideArrow.pose(arrow, CFrame.lookAt(spot, spot + forward), 0)
		end
	end

	return { update = update, hide = hide }
end

return GuidePath
