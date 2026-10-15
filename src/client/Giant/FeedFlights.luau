--!strict
--[[
	FeedFlights

	Los peces que vuelan a la boca del gigante comparten UN bucle de
	RenderStepped (no uno por pez): con 40-50 jugadores dando de comer, cada
	conexión extra cuesta. El bucle se conecta con el primer vuelo y se
	desconecta cuando no queda ninguno. Solo efecto visual.
]]

local RunService = game:GetService("RunService")

local FishModel = require(script.Parent.Parent.Effects.FishModel)

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

local FeedFlights = {}

local flights: { Flight } = {}
local connection: RBXScriptConnection? = nil

local function step(dt: number)
	for index = #flights, 1, -1 do
		local flight = flights[index]
		flight.elapsed += dt
		local t = math.min(flight.elapsed / flight.seconds, 1)
		if flight.model.Parent then
			flight.model:PivotTo(
				FishModel.arcPose(
					flight.from,
					flight.target(),
					flight.height,
					t,
					flight.elapsed,
					flight.spins
				)
			)
		end
		if t >= 1 then
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
