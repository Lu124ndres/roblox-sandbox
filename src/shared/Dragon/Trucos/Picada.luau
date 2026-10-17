--!strict
--[[
	Picada: sube un poco la nariz y levanta las alas (anticipación), las pliega
	y se tira en picada acelerando (la cabeza adelante, la cola atrás, estelas
	en las puntas); abajo abre las alas, se recupera con aletazos fuertes que la
	levantan (flap) y vuelve a su altura en arco.
]]

local C = require(script.Parent.Parent.Parent.Minotauro.Trucos.Curvas)

return table.freeze({
	name = "picada",
	seconds = 4.2,
	events = { { at = 0.12, kind = "whoosh" }, { at = 0.55, kind = "flap" } },
	pose = function(u: number, L: number): { [string]: number }
		local windup = C.bell(C.span(u, 0, 0.14))
		local dive = C.smooth(C.span(u, 0.08, 0.5))
		local pull = C.smooth(C.span(u, 0.5, 1))
		local tucked = C.bell(C.span(u, 0.08, 0.56))
		local recover = C.bell(C.span(u, 0.5, 1))
		return {
			dy = -(25 + L * 0.4) * (dive - pull) + 3 * windup,
			fold = tucked,
			spread = 0.4 * windup,
			flap = if u < 0.5 then 0.15 + 0.6 * windup else 1.6 * recover + 0.4,
			pitch = 0.2 * windup - 0.8 * tucked + 0.5 * C.bell(C.span(u, 0.45, 0.95)),
			speed = 1 + 0.8 * C.bell(u),
			neck = -0.15 * tucked,
			head = 0.15 * windup - 0.15 * tucked + 0.2 * recover,
			tailUp = -0.25 * tucked + 0.2 * recover,
		}
	end,
})
