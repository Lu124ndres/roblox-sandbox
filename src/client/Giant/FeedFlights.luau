--!strict
--[[
	FeedFlights

	Los peces que vuelan a la boca del gigante comparten UN bucle de
	RenderStepped (no uno por pez): con 40-50 jugadores dando de comer, cada
	conexión extra cuesta. El bucle se conecta con el primer vuelo y se
	desconecta cuando no queda ninguno. Solo efecto visual.

	Los peces se estiran al salir y al llegar y se redondean arriba (Squash),
	salvo con efectos reducidos o con más de SQUASH_MAX en el aire.
]]

local RunService = game:GetService("RunService")

local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local FishModel = require(script.Parent.Parent.Effects.FishModel)
local Squash = require(script.Parent.Parent.Effects.Squash)

type Flight = {
	model: Model,
	from: Vector3,
	target: () -> Vector3, -- se pide cada cuadro: la boca puede moverse (la orca nada)
	height: number,
	seconds: number,
	spins: number,
	elapsed: number,
	onDone: () -> (),
}

local SQUASH_MAX = 12
local STRETCH = 0.45

local FeedFlights = {}

local flights: { Flight } = {}
local connection: RBXScriptConnection? = nil

local function step(dt: number)
	local squash = #flights <= SQUASH_MAX and not ClientSettings.get("lowFx")
	for index = #flights, 1, -1 do
		local flight = flights[index]
		flight.elapsed += dt
		local t = math.min(flight.elapsed / flight.seconds, 1)
		local model = flight.model
		if model.Parent then
			local pose = FishModel.arcPose(
				flight.from,
				flight.target(),
				flight.height,
				t,
				flight.elapsed,
				flight.spins
			)
			if squash then
				Squash.pivot(model, pose, Squash.arc(t, STRETCH))
			else
				model:PivotTo(pose)
			end
		end
		if t >= 1 then
			-- Vuelve a su forma antes de volver al pool.
			Squash.pivot(model, model:GetPivot(), 1)
			-- Quita sin desplazar la lista: el último ocupa su lugar.
			flights[index] = flights[#flights]
			flights[#flights] = nil
			task.spawn(flight.onDone)
		end
	end
	if #flights == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Vuelos en el aire ahora mismo.
function FeedFlights.count(): number
	return #flights
end

-- El modelo vuela en arco de "from" a target() en `seconds`; onDone al llegar
-- (quien llama destruye el modelo ahí).
function FeedFlights.launch(
	model: Model,
	from: Vector3,
	target: () -> Vector3,
	height: number,
	seconds: number,
	spins: number,
	onDone: () -> ()
)
	table.insert(flights, {
		model = model,
		from = from,
		target = target,
		height = height,
		seconds = math.max(seconds, 0.05),
		spins = spins,
		elapsed = 0,
		onDone = onDone,
	})
	if not connection then
		connection = RunService.RenderStepped:Connect(step)
	end
end

return FeedFlights
