--!strict
--[[
	Minotauro/Habitos

	Los hábitos de cada etapa (Minotauro/Etapas los pone en rutina y paso):
		rutina  lo que hace cuando nadie le da de comer (Minotauro/Rutina):
		        cycle  segundos de cada estadía: camina a un lugar y hace cosas ahí
		        roam   qué parte del radio libre del cráter recorre (0..1)
		        gait   fracción de su velocidad de caminar cuando pasea
		        gap    segundos quieto entre una cosa y la siguiente
		        stay   cuántas cosas hace como mucho en cada lugar
		        list   lo que elige (Minotauro/Posturas; "truco" = uno de sus tricks)
		        siesta si sentado puede quedarse dormido
		paso    su manera de caminar (Pose.walk): bounce (saltito en cada paso,
		        fracción del alto), knee (rodillas siempre algo dobladas), arms (vaivén
		        de los brazos), out (brazos abiertos), lean (tronco: atrás +), chin
		        (cabeza arriba +), sway (cuánto se bambolea) y tail (cola arriba; los
		        grandes la levantan un poco para que la pata de atrás no la patee)
	El becerro trota, cambia seguido de lugar y de idea; el joven camina sacando
	pecho y se luce; el adulto pasea agachado y pesado; la forma final camina poco
	y lento y se sienta a dormitar.
]]

export type Rutina = {
	cycle: number,
	roam: number,
	gait: number,
	gap: number,
	stay: number,
	list: { string },
	siesta: boolean,
}

export type Paso = {
	bounce: number,
	knee: number,
	arms: number,
	out: number,
	lean: number,
	chin: number,
	sway: number,
	tail: number,
}

local rutinas: { Rutina } = {
	-- becerro: inquieto y juguetón; trota, cambia seguido de lugar y de idea
	{
		cycle = 24,
		roam = 0.32,
		gait = 0.9,
		gap = 0.8,
		stay = 3,
		list = {
			"olfatear",
			"truco",
			"sentarse",
			"mirarJugador",
			"truco",
			"estirarse",
			"sentarse",
			"mirarCielo",
		},
		siesta = false,
	},
	-- joven: fanfarrón; camina sacando pecho, se luce y mira a la gente
	{
		cycle = 30,
		roam = 0.42,
		gait = 0.6,
		gap = 1.4,
		stay = 3,
		list = {
			"truco",
			"mirarJugador",
			"sentarse",
			"estirarse",
			"truco",
			"olfatear",
			"mirarJugador",
			"mirarCielo",
		},
		siesta = false,
	},
	-- adulto: pesado; pasea agachado, se sienta y a veces dormita
	{
		cycle = 36,
		roam = 0.5,
		gait = 0.45,
		gap = 2.2,
		stay = 3,
		list = {
			"sentarse",
			"olfatear",
			"truco",
			"mirarCielo",
			"estirarse",
			"truco",
			"mirarJugador",
		},
		siesta = true,
	},
	-- forma final: enorme y lenta; camina poco, se sienta pesado y dormita
	{
		cycle = 44,
		roam = 0.55,
		gait = 0.35,
		gap = 3,
		stay = 3,
		list = { "sentarse", "mirarCielo", "truco", "sentarse", "estirarse", "mirarJugador" },
		siesta = true,
	},
}

local pasos: { Paso } = {
	-- becerro
	{
		bounce = 0.025,
		knee = 0.1,
		arms = 1.2,
		out = 0,
		lean = -0.03,
		chin = 0.05,
		sway = 1,
		tail = 0.35,
	},
	-- joven
	{
		bounce = 0.004,
		knee = 0,
		arms = 1.3,
		out = 0.15,
		lean = 0.1,
		chin = 0.12,
		sway = 1.6,
		tail = 0.2,
	},
	-- adulto
	{
		bounce = 0,
		knee = 0.15,
		arms = 0.8,
		out = 0.12,
		lean = -0.05,
		chin = -0.05,
		sway = 1.3,
		tail = 0.25,
	},
	-- forma final
	{
		bounce = 0,
		knee = 0.2,
		arms = 0.6,
		out = 0.15,
		lean = -0.02,
		chin = -0.08,
		sway = 1.6,
		tail = 0.2,
	},
}

return table.freeze({ rutinas = rutinas, pasos = pasos })
