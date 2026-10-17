--!strict
--[[
	Dragon/Etapas

	Cómo vuela cada etapa del dragón (modelo DragonMarinoE1..E4):
		beat       aletazos por segundo (la cría aletea rápido, el anciano lento
		           y poderoso)
		amplitude  cuánto baja y sube el ala (rad)
		glide      fracción del vuelo que planea sin aletear
		speed      velocidad de crucero (multiplica la de su tamaño)
		bank       cuánto se ladea en las curvas
		tricks     los trucos que hace (Dragon/Trucos) y cada cuántos segundos
		voice      tono de sus rugidos; fire tamaño del fuego
		pace       cuánto más lentas son sus posturas, su despegue y su
		           aterrizaje (1 = cría; la anciana tarda más en todo)
		bounce     cuánto rebota al aterrizar y al saltar (la cría rebota, la
		           anciana se asienta con peso)
		rutina     lo que hace cuando nadie le da de comer (Dragon/Habitos)
]]

local Habitos = require(script.Parent.Habitos)

export type Rutina = Habitos.Rutina

export type Profile = {
	beat: number,
	amplitude: number,
	glide: number,
	speed: number,
	bank: number,
	tricks: { string },
	trickEvery: number,
	voice: number,
	fire: number,
	pace: number,
	bounce: number,
	rutina: Rutina,
}

local PROFILES: { [number]: Profile } = {
	{ -- cría: juguetona, aletea rápido, da volteretas
		beat = 2.6,
		amplitude = 0.8,
		glide = 0.12,
		speed = 1.2,
		bank = 1.1,
		tricks = { "voltereta", "rugido", "fuego", "voltereta" },
		trickEvery = 11,
		voice = 1.55,
		fire = 0.6,
		pace = 1,
		bounce = 1,
		rutina = Habitos.rutinas[1],
	},
	{ -- joven: ágil, picadas y volteretas
		beat = 1.8,
		amplitude = 0.72,
		glide = 0.28,
		speed = 1.05,
		bank = 0.95,
		tricks = { "fuego", "rugido", "picada", "voltereta" },
		trickEvery = 13,
		voice = 1.2,
		fire = 0.9,
		pace = 1.12,
		bounce = 0.7,
		rutina = Habitos.rutinas[2],
	},
	{ -- adulto: poderoso, planea más
		beat = 1.35,
		amplitude = 0.66,
		glide = 0.4,
		speed = 0.95,
		bank = 0.8,
		tricks = { "fuego", "rugido", "picada", "planeo" },
		trickEvery = 15,
		voice = 0.95,
		fire = 1.15,
		pace = 1.3,
		bounce = 0.45,
		rutina = Habitos.rutinas[3],
	},
	{ -- anciano: alas enormes, aletazos lentos que mueven el aire
		beat = 0.95,
		amplitude = 0.58,
		glide = 0.5,
		speed = 0.85,
		bank = 0.7,
		tricks = { "rugido", "fuego", "planeo", "picada" },
		trickEvery = 17,
		voice = 0.72,
		fire = 1.45,
		pace = 1.55,
		bounce = 0.25,
		rutina = Habitos.rutinas[4],
	},
}

local Etapas = {}

-- La etapa sale del nombre del modelo (…E1 … E4); sin modelo, la cría.
function Etapas.forModel(name: string?): Profile
	local stage = if name then tonumber(string.match(name, "E(%d)$")) else nil
	return PROFILES[math.clamp(stage or 1, 1, #PROFILES)]
end

return table.freeze(Etapas)
