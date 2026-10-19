--!strict
--[[
	Analytics/Bus

	El puente entre los módulos de datos y la telemetría: PlayerData avisa aquí
	cuando entran o salen monedas, cuando pesca o cuando gana una kill, y
	Analytics (que lee PlayerData) se engancha en init. Así PlayerData no
	requiere a Analytics y no hay ciclo de require. Sin Analytics, los avisos
	no hacen nada.

	source / sink: de dónde vienen o adónde van las monedas ("alimentar",
	"diario", "tienda:Rod", "renacer"...). Ver Analytics/Economia.
]]

export type Listeners = {
	coins: (player: Player, amount: number, source: string) -> (),
	spend: (player: Player, amount: number, sink: string) -> (),
	catch: (player: Player, fishId: string, added: number, caughtBefore: number) -> (),
	kill: (player: Player, killsBefore: number, killsAfter: number) -> (),
}

local Bus: Listeners = {
	coins = function(_player: Player, _amount: number, _source: string) end,
	spend = function(_player: Player, _amount: number, _sink: string) end,
	catch = function(_player: Player, _fishId: string, _added: number, _caughtBefore: number) end,
	kill = function(_player: Player, _killsBefore: number, _killsAfter: number) end,
}

return Bus
