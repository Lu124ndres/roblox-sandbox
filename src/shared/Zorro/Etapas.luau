--!strict
--[[
	Zorro/Etapas

	Cómo mueve las colas cada etapa del zorro de agua (modelo ZorroDeAguaE1..E4, o
	ZorroDeAguaE1_v2..E4_v2 del modelo de bloques). Lo usa Zorro/Colas:
		colas    cuántas tiene la etapa (1, 3, 6 y 9); el código usa las que
		         encuentra en el modelo, esto es solo la referencia de la biblia
		ritmo    multiplica la frecuencia de la onda y del meneo (la cría es
		         rápida y juguetona, la forma final lenta y majestuosa)
		fuerza   multiplica la amplitud de la onda y del meneo
		peso     multiplica la rigidez de los resortes (menos = más pesada: tarda
		         más en seguir al cuerpo)
		rebote   amortiguación de los resortes (1 = llega sin pasarse; la cría
		         rebota un poco, la forma final casi nada)
		abanico  cuánto se abre el borde del abanico al lucirse (rad)
		latigo   fuerza de los latigazos y de la reacción al cuerpo (giros, saltos)
]]

export type Profile = {
	etapa: number,
	colas: number,
	ritmo: number,
	fuerza: number,
	peso: number,
	rebote: number,
	abanico: number,
	latigo: number,
}

local PROFILES: { [number]: Profile } = {
	{ -- cría: una cola juguetona que no para quieta
		etapa = 1,
		colas = 1,
		ritmo = 1.45,
		fuerza = 1.25,
		peso = 1.3,
		rebote = 0.78,
		abanico = 0.35,
		latigo = 1.25,
	},
	{ -- joven: inquieto, tres colas vivas
		etapa = 2,
		colas = 3,
		ritmo = 1.2,
		fuerza = 1.1,
		peso = 1.12,
		rebote = 0.82,
		abanico = 0.45,
		latigo = 1.1,
	},
	{ -- adulto: seguro, el abanico de seis
		etapa = 3,
		colas = 6,
		ritmo = 0.95,
		fuerza = 1,
		peso = 0.95,
		rebote = 0.86,
		abanico = 0.5,
		latigo = 1,
	},
	{ -- forma final: nueve colas enormes, lentas y pesadas
		etapa = 4,
		colas = 9,
		ritmo = 0.72,
		fuerza = 0.9,
		peso = 0.78,
		rebote = 0.9,
		abanico = 0.5,
		latigo = 0.85,
	},
}

local Etapas = {}

-- La etapa sale del nombre del modelo (…E1 … E4, o con sufijo: …E1_v2 del modelo de
-- bloques, …E4_code en ServerStorage); sin modelo, la cría.
function Etapas.forModel(name: string?): Profile
	local digit = if name
		then string.match(name, "E(%d)_%w+$") or string.match(name, "E(%d)$")
		else nil
	local stage = tonumber(digit)
	return PROFILES[math.clamp(stage or 1, 1, #PROFILES)]
end

return table.freeze(Etapas)
