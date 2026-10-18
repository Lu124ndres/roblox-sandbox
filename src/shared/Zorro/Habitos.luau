--!strict
--[[
	Zorro/Habitos

	Cómo vive cada etapa del zorro de agua cuando nadie le da de comer (lo lee
	Zorro/Rutina). Las medidas van en altos del zorro (16.5, 44, 82.5 y 165 studs):
		ciclo     segundos de cada estadía: va a un lugar y hace cosas ahí
		lugares   peso de cada lugar de Zorro/Guarida (0 = no va); además Rutina
		          descarta los que no le caben (ver Rutina/Lugares)
		racha     cuántos ciclos seguidos se queda en el mismo lugar (en cada uno se
		          acomoda en otro punto del témpano)
		velocidad altos/s al pasear (la cría trota, la forma final apenas camina)
		zancada   altos que avanza en un paso completo (walkPhase de 0 a 2π)
		pisadas   cuántas pisadas suenan por paso completo
		giro      rad/s como mucho al girar en el lugar
		arranque  segundos que tarda en llegar a su velocidad (y en frenar)
		pausa     segundos quieto, respirando, entre una cosa y otra (min, max)
		mirar     probabilidad de que una vez, en vez de una conducta, solo mire
		          alrededor (min y max de segundos en `mirada`)
		desvio    rad como mucho que se aparta de mirar de frente a la puerta en
		          cada estadía (los trucos, siempre de frente)
	La cría es inquieta (estadías cortas, pausas breves, casi siempre hace algo);
	el joven pasea y se luce; el adulto es seguro; la forma final se mueve poco,
	lento y con peso, y casi siempre solo mira.
]]

export type Habito = {
	ciclo: number,
	lugares: { [string]: number },
	racha: number,
	velocidad: number,
	zancada: number,
	pisadas: number,
	giro: number,
	arranque: number,
	pausa: { number },
	mirar: number,
	mirada: { number },
	desvio: number,
}

local HABITOS: { Habito } = {
	{ -- cría: va y viene por los témpanos de cerca de la puerta y casi nunca para
		ciclo = 30,
		lugares = { Centro = 3, Puerta = 2.5, Orilla = 2.5, Fondo = 0, Vigia = 0 },
		racha = 3,
		velocidad = 0.7,
		zancada = 0.22, -- con 0.3 la mano y el pie del mismo lado se cruzan (zorro_v2_poses)
		pisadas = 1,
		giro = 2.2,
		arranque = 0.6,
		pausa = { 1, 2.2 },
		mirar = 0.1,
		mirada = { 1.5, 3 },
		desvio = 0.35,
	},
	{ -- joven: pasea por todo el lago y se luce en la roca
		ciclo = 36,
		lugares = { Centro = 2, Puerta = 2, Orilla = 2, Fondo = 2, Vigia = 1.5 },
		racha = 2,
		velocidad = 0.4,
		zancada = 0.24,
		pisadas = 2,
		giro = 1.6,
		arranque = 0.9,
		pausa = { 1.2, 3 },
		mirar = 0.15,
		mirada = { 2, 4 },
		desvio = 0.3,
	},
	{ -- adulto: seguro; cambia menos de lugar y se queda más
		ciclo = 50,
		lugares = { Centro = 2, Puerta = 1.5, Orilla = 1.5, Fondo = 2, Vigia = 1.5 },
		racha = 1,
		velocidad = 0.28,
		zancada = 0.24,
		pisadas = 2,
		giro = 1.1,
		arranque = 1.2,
		pausa = { 1.6, 3.5 },
		mirar = 0.25,
		mirada = { 2.5, 5 },
		desvio = 0.25,
	},
	{ -- forma final: no cabe en otro lugar que el centro; gira despacio y mira
		ciclo = 60,
		lugares = { Centro = 1, Puerta = 0, Orilla = 0, Fondo = 0, Vigia = 0 },
		racha = 1,
		velocidad = 0.18,
		zancada = 0.24,
		pisadas = 2,
		giro = 0.7,
		arranque = 1.6,
		pausa = { 2.2, 4 },
		mirar = 0.35,
		mirada = { 3, 6 },
		desvio = 0.2,
	},
}

local Habitos = {}

function Habitos.de(etapa: number): Habito
	return HABITOS[math.clamp(math.floor(etapa), 1, #HABITOS)]
end

return table.freeze(Habitos)
