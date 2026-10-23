--!strict
--[[
	FeedPose

	El cuerpo de quien alimenta al gigante, como un cuidador de orcas que le
	lanza pescado: por encima del hombro, con el pie contrario adelante y el
	tronco girando hacia el lanzamiento (Body/BodyPoses throwRight y
	throwLeft). Los brazos se turnan: mientras uno lanza, el otro ya carga el
	siguiente detrás de la cabeza, así el chorro de peces se ve como un
	molino. FeedThrow llama throw en cada pez, a su ritmo de siempre; sin
	peces por REST_AFTER segundos, el cuerpo vuelve a la pose normal.

	Solo animación: los peces salen cuando salían, ahora desde la mano.
]]

local BodyPose = require(script.Parent.Parent.Body.BodyPose)

type Thrower = { body: BodyPose.BodyPose, right: boolean, last: number }

local REST_AFTER = 0.45
local MIN_SECONDS, MAX_SECONDS = 0.09, 0.28 -- lo que tarda el brazo en lanzar
local CHEST = Vector3.new(0, 2, 0) -- sin cuerpo animable (R6), sale del pecho como antes

local FeedPose = {}

local throwers: { [Model]: Thrower } = setmetatable({} :: any, { __mode = "k" })

-- Lanza un pez: cambia de brazo y devuelve dónde está la mano que lanza.
-- gap = segundos hasta el próximo pez de este jugador.
function FeedPose.throw(character: Model, gap: number): Vector3
	local thrower = throwers[character]
	if not thrower then
		local body = BodyPose.get(character)
		if body then
			thrower = { body = body, right = false, last = 0 }
			throwers[character] = thrower
		end
	end
	if not thrower then
		return character:GetPivot().Position + CHEST
	end
	thrower.right = not thrower.right
	local now = os.clock()
	thrower.last = now
	thrower.body.play(
		if thrower.right then "throwRight" else "throwLeft",
		math.clamp(gap, MIN_SECONDS, MAX_SECONDS)
	)
	task.delay(REST_AFTER, function()
		if thrower.last == now then
			thrower.body.play("rest", 0.4)
		end
	end)
	local hand = character:FindFirstChild(if thrower.right then "RightHand" else "LeftHand")
	if hand and hand:IsA("BasePart") then
		return hand.Position
	end
	return character:GetPivot().Position + CHEST
end

return FeedPose
