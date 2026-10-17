--!strict
--[[
	Dragon/Habitos

	Lo que hace cada etapa del dragón cuando nadie le da de comer (Dragon/Rutina):
		cycle    segundos de cada vuelta de la rutina: vuela sus vueltas y, si le
		         toca, al final se posa en una roca y despega justo al terminar
		perch    probabilidad de posarse en una vuelta (0..1)
		stay     segundos posado (varía entre 75 % y 125 %; nunca deja menos de
		         Rutina.MIN_FLY volando al principio de la vuelta)
		nest     probabilidad de elegir el nido (la roca central) para posarse
		sleep    probabilidad de dormirse en el nido (en otra roca, la mitad): se
		         enrosca, duerme y despierta antes de despegar
		gap      segundos quieto entre una cosa y la siguiente, posado
		list     lo que elige posado (Dragon/Posturas)
	La cría vuela mucho, se posa poco y rebota; la joven y la adulta se lucen
	posadas (rugen, echan fuego al cielo); la anciana planea, se posa casi
	siempre y se duerme en el nido.
]]

export type Rutina = {
	cycle: number,
	perch: number,
	stay: number,
	nest: number,
	sleep: number,
	gap: number,
	list: { string },
}

local rutinas: { Rutina } = {
	-- cría: inquieta; vuela casi siempre, se posa un rato y salta en la roca
	{
		cycle = 42,
		perch = 0.4,
		stay = 13,
		nest = 0.2,
		sleep = 0.1,
		gap = 0.4,
		list = { "brinco", "mirar", "estirarse", "brinco", "rugir", "acicalarse", "fuegoCielo" },
	},
	-- joven: fanfarrona; se posa a lucirse
	{
		cycle = 46,
		perch = 0.5,
		stay = 17,
		nest = 0.25,
		sleep = 0.2,
		gap = 0.8,
		list = { "rugir", "mirar", "fuegoCielo", "estirarse", "acicalarse", "mirar" },
	},
	-- adulta: se posa seguido, vigila desde la roca
	{
		cycle = 52,
		perch = 0.65,
		stay = 24,
		nest = 0.35,
		sleep = 0.4,
		gap = 1.2,
		list = { "mirar", "acicalarse", "rugir", "estirarse", "fuegoCielo", "mirar" },
	},
	-- anciana: enorme y lenta; planea, se posa casi siempre y duerme en el nido
	{
		cycle = 60,
		perch = 0.85,
		stay = 32,
		nest = 0.5,
		sleep = 0.75,
		gap = 1.8,
		list = { "mirar", "acicalarse", "estirarse", "mirar", "rugir", "fuegoCielo" },
	},
}

return table.freeze({ rutinas = rutinas })
