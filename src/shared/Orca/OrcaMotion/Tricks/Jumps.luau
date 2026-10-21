--!strict
--[[
	OrcaMotion/Tricks/Jumps

	Los trucos que sacan a la orca del agua o la mandan al fondo:
		breach   salto completo (Salto): toma impulso desde abajo, sale casi
		         vertical, gira en el aire, cae de costado o de espalda, se hunde
		         de verdad y vuelve a soplar. `twist` en vueltas (0.25 de costado,
		         0.5 de espalda); `style`: talla, sink, flop, times, size, exit.
		hops     saltitos seguidos (Saltitos): `count` arcos de `height`.
		dive     zambullida honda con la cola afuera (Zambullida) hasta `depth`.
	Sin `style.talla` la física se ajusta a `seconds` (así los usan los festejos
	al comer); con talla, la gravedad y el ritmo son los de su tamaño.
]]

local Saltitos = require(script.Parent.Saltitos)
local Salto = require(script.Parent.Salto)
local Zambullida = require(script.Parent.Zambullida)

export type BreachStyle = Salto.Style
export type HopStyle = Saltitos.Style
export type DiveStyle = Zambullida.Style

return table.freeze({
	breach = Salto.breach,
	hops = Saltitos.hops,
	dive = Zambullida.dive,
})
