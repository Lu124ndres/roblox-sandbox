--!strict
--[[
	Trajes/Estilos/Marinero

	El traje de todos. Alegre: brazos sueltos, respira, mira a los lados
	cuando está quieto y rebota un poco al caminar. En la vitrina saluda con
	la mano cada tanto. Sin efectos (lo usa todo el servidor).
]]

local Tipos = require(script.Parent.Parent.Tipos)

local function wave(now: number, every: number, length: number): number
	local t = now % every
	if t > length then
		return 0
	end
	return math.sin(math.pi * t / length) ^ 0.5
end

local style: Tipos.Style = {
	arms = 1.1,
	legs = 1,
	pose = function(ctx: Tipos.Context): { [string]: CFrame }
		local now = ctx.now
		local still = math.clamp(1 - ctx.speed / 6, 0, 1)
		local pose = {
			Pecho = CFrame.Angles(0.025 * math.sin(now * 1.7), 0, 0),
			Cabeza = CFrame.Angles(
				0.06 * math.sin(now * 0.9) * still,
				0.35 * math.sin(now * 0.37) * still,
				0.05 * math.sin(now * 0.6)
			),
		}
		if not ctx.display then
			return pose
		end
		local w = wave(now, 7, 2.6)
		if w > 0 then -- levanta el brazo derecho y mueve la mano
			pose.BrazoDer = CFrame.Angles(0, 0, 2.5 * w)
			pose.CodoDer = CFrame.Angles(0, 0, (0.35 + 0.45 * math.sin(now * 11)) * w)
			pose.Cabeza = pose.Cabeza * CFrame.Angles(0, 0, -0.12 * w)
		end
		return pose
	end,
	effects = function(_fx: Tipos.Fx) end,
}

return style
