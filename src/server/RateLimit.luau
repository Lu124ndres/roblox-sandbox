--!strict
--[[
	RateLimit

	Límite de frecuencia por jugador para los RemoteEvents (cubeta de fichas):
	cada remote tiene `perSecond` fichas por segundo y hasta `burst`
	guardadas. Lo que pasa del límite se ignora en silencio; si un jugador
	manda muchísimo más de lo normal, se anota en la salida para revisarlo.
	Nunca expulsa: un cliente con lag puede mandar ráfagas legítimas.
]]

local Players = game:GetService("Players")

export type Limiter = (player: Player) -> boolean

local RateLimit = {}

local SUSPICIOUS_DROPS = 100 -- avisos en la salida cada tantos pedidos ignorados

local limiters: { { [Player]: any } } = {}

Players.PlayerRemoving:Connect(function(player: Player)
	for _, buckets in limiters do
		buckets[player] = nil
	end
end)

function RateLimit.new(name: string, perSecond: number, burst: number): Limiter
	local buckets: { [Player]: { tokens: number, at: number, dropped: number } } = {}
	table.insert(limiters, buckets)
	return function(player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if not bucket then
			bucket = { tokens = burst, at = now, dropped = 0 }
			buckets[player] = bucket
		end
		bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.at) * perSecond)
		bucket.at = now
		if bucket.tokens >= 1 then
			bucket.tokens -= 1
			return true
		end
		bucket.dropped += 1
		if bucket.dropped % SUSPICIOUS_DROPS == 0 then
			warn(
				`RateLimit: {player.Name} superó el límite de {name} ({bucket.dropped} pedidos ignorados)`
			)
		end
		return false
	end
end

-- Envuelve un handler de OnServerEvent: solo lo llama si el jugador está dentro del límite.
function RateLimit.wrap(
	name: string,
	perSecond: number,
	burst: number,
	handler: (Player, ...any) -> ()
): (Player, ...any) -> ()
	local allow = RateLimit.new(name, perSecond, burst)
	return function(player: Player, ...: any)
		if allow(player) then
			handler(player, ...)
		end
	end
end

return RateLimit
