--!strict
--[[
	Trajes/Capa

	Mueve la capa de un traje (huesos Capa1, colgado del pecho, y Capa2, la
	mitad de abajo): quieta cae casi derecha y se mece apenas; al correr vuela
	hacia atrás y ondea más rápido, con la mitad de abajo un poco atrasada (la
	onda baja por la tela). La subida se suaviza para que no salte al frenar.
	En la vitrina flamea un poco, como con viento.
]]

local Tipos = require(script.Parent.Tipos)

local RUN_SPEED = 22 -- studs/s: con esto la capa vuela del todo
local EASE = 3 -- qué tan rápido sigue a la velocidad (1/s)

local Capa = {}

function Capa.new(fx: Tipos.Fx): Tipos.Tick
	local lift = 0
	local last: number? = nil
	return function(ctx: Tipos.Context)
		local dt = if last then math.clamp(ctx.now - last, 0, 0.1) else 0
		last = ctx.now
		local target = if ctx.display then 0.2 else math.clamp(ctx.speed / RUN_SPEED, 0, 1)
		lift += (target - lift) * math.min(1, dt * EASE)
		local pace = ctx.now * (2.2 + 6 * lift)
		local top = math.sin(pace) * (0.04 + 0.1 * lift)
		local bottom = math.sin(pace - 1.2) * (0.06 + 0.16 * lift)
		-- En el espacio del personaje +Z es atrás: girar en -X lleva la punta hacia atrás.
		fx.pose("Capa1", CFrame.Angles(-(0.04 + 0.95 * lift) - top, 0, 0))
		fx.pose("Capa2", CFrame.Angles(-(0.03 + 0.3 * lift) - bottom, 0, 0))
	end
end

return table.freeze(Capa)
