--!strict
--[[
	GiantEyesData

	GENERADO por tools/blender/ojos_medir.py: no se edita a mano, se vuelve a correr el script.

	Dónde está cada ojo de los gigantes v2, para las pupilas que siguen al jugador
	(src/client/Giant/GiantEyes.luau). Todo en ejes de Blender (x = izquierda del personaje,
	-y = frente, z = arriba), en las unidades de la malla exportada al FBX y en la pose de bind.
	La caja (boundsMin/boundsMax) es la de toda la malla: su tamaño es MeshPart.Size y su centro,
	MeshPart.CFrame. A la MeshPart: (x, y, z) -> (-x, z, y) y local = (p - centro) / tamaño * Size.

	Con `cover`, la malla ya trae una pupila pintada: se tapa el ojo con una placa de ese color
	(la cara medida es la de la tapa, delante de la pupila pintada) y la pupila móvil va encima.
]]

export type Eye = {
	center: Vector3, -- centro de la cara visible del ojo (BU, ejes de Blender)
	normal: Vector3, -- unitario, hacia afuera del ojo (ejes de Blender)
	up: Vector3, -- unitario, el "arriba" del ojo en su plano (ejes de Blender)
	size: Vector2, -- ancho y alto de la cara del ojo en su plano (BU)
}

export type ModelEyes = {
	bone: string, -- el hueso que lleva los ojos (normalmente "Cabeza")
	boundsMin: Vector3, -- caja de TODA la malla exportada (BU, ejes de Blender, pose de bind)
	boundsMax: Vector3,
	requiresBone: string?, -- se usa solo si el modelo tiene este hueso (orca v2: "OjoIzqMira")
	cover: Color3?, -- tapa del color del ojo que esconde la pupila pintada en la malla
	eyes: { Eye }, -- izquierdo primero
}

-- Clave: nombre del modelo en el juego ("MinotauroE3", "OrcaE1"...).
local data: { [string]: ModelEyes } = {
	-- assets/blender/minotauro_v2/e1_rig.blend
	MinotauroE1 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-6.9194, -5.3226, 0),
		boundsMax = Vector3.new(6.9194, 5.3226, 16.5001),
		eyes = {
			{
				center = Vector3.new(1.3306, -3.1936, 12.7742),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(1.5968, 1.0645),
			},
			{
				center = Vector3.new(-1.3306, -3.1936, 12.7742),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(1.5968, 1.0645),
			},
		},
	},
	-- assets/blender/minotauro_v2/e2_rig.blend
	MinotauroE2 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-20.7581, -14.371, 0),
		boundsMax = Vector3.new(20.7581, 15.9678, 44.7098),
		cover = Color3.fromRGB(255, 188, 63),
		eyes = {
			{
				center = Vector3.new(3.992, -7.9839, 36.7259),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(4.7903, 3.1936),
			},
			{
				center = Vector3.new(-3.992, -7.9839, 36.7259),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(4.7903, 3.1936),
			},
		},
	},
	-- assets/blender/minotauro_v2/e3_rig.blend
	MinotauroE3 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-42.5808, -29.2743, 0),
		boundsMax = Vector3.new(42.5808, 31.9356, 82.5003),
		cover = Color3.fromRGB(255, 179, 56),
		eyes = {
			{
				center = Vector3.new(7.9839, -18.6291, 71.8551),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(5.3226, 5.3226),
			},
			{
				center = Vector3.new(-7.9839, -18.6291, 71.8551),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(5.3226, 5.3226),
			},
		},
	},
	-- assets/blender/minotauro_v2/e4_rig.blend
	MinotauroE4 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-90.4842, -53.226, 0),
		boundsMax = Vector3.new(90.4842, 69.1938, 165.0006),
		eyes = {
			{
				center = Vector3.new(15.9678, -37.2582, 143.7102),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(10.6452, 10.6452),
			},
			{
				center = Vector3.new(-15.9678, -37.2582, 143.7102),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(10.6452, 10.6452),
			},
		},
	},
	-- assets/blender/dragon_v2/e1_rig.blend
	DragonMarinoE1 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-4.95, -4.675, 0.275),
		boundsMax = Vector3.new(4.95, 4.6455, 6.6),
		cover = Color3.fromRGB(63, 230, 210),
		eyes = {
			{
				center = Vector3.new(1.1, -3.1625, 5.225),
				normal = Vector3.new(1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(0.825, 0.55),
			},
			{
				center = Vector3.new(-1.1, -3.1625, 5.225),
				normal = Vector3.new(-1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(0.825, 0.55),
			},
		},
	},
	-- assets/blender/dragon_v2/e2_rig.blend
	DragonMarinoE2 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-13.2, -13.2, 0),
		boundsMax = Vector3.new(13.2, 12.375, 15.675),
		eyes = {
			{
				center = Vector3.new(2.475, -10.3125, 12.7875),
				normal = Vector3.new(1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(0.825, 0.825),
			},
			{
				center = Vector3.new(-2.475, -10.3125, 12.7875),
				normal = Vector3.new(-1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(0.825, 0.825),
			},
		},
	},
	-- assets/blender/dragon_v2/e3_rig.blend
	DragonMarinoE3 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-24.75, -23.375, 0),
		boundsMax = Vector3.new(24.75, 24.75, 21.8833),
		eyes = {
			{
				center = Vector3.new(4.125, -17.875, 17.1875),
				normal = Vector3.new(1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(2.75, 1.375),
			},
			{
				center = Vector3.new(-4.125, -17.875, 17.1875),
				normal = Vector3.new(-1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(2.75, 1.375),
			},
		},
	},
	-- assets/blender/dragon_v2/e4_rig.blend
	DragonMarinoE4 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-49.5, -46.75, -2.75),
		boundsMax = Vector3.new(49.5, 49.2667, 49.3524),
		eyes = {
			{
				center = Vector3.new(11, -35.75, 39.875),
				normal = Vector3.new(1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(5.5, 2.75),
			},
			{
				center = Vector3.new(-11, -35.75, 39.875),
				normal = Vector3.new(-1, 0, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(5.5, 2.75),
			},
		},
	},
	-- assets/blender/zorro_v2/e1_rig.blend
	ZorroDeAguaE1 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-3.7258, -10.6452, 0),
		boundsMax = Vector3.new(3.7258, 12.729, 16.5),
		eyes = {
			{
				center = Vector3.new(1.5635, -9.0484, 11.377),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(1.2641, 1.3306),
			},
			{
				center = Vector3.new(-1.5635, -9.0484, 11.377),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(1.2641, 1.3306),
			},
		},
	},
	-- assets/blender/zorro_v2/e2_rig.blend
	ZorroDeAguaE2 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-32.8667, -26.7143, 0),
		boundsMax = Vector3.new(32.8667, 37.5809, 44),
		eyes = {
			{
				center = Vector3.new(3.9147, -22, 31.4286),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(2.1607, 2.3571),
			},
			{
				center = Vector3.new(-3.9147, -22, 31.4286),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(2.1607, 2.3571),
			},
		},
	},
	-- assets/blender/zorro_v2/e3_rig.blend
	ZorroDeAguaE3 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-50.3387, -47.9032, 0),
		boundsMax = Vector3.new(50.3387, 66.5323, 82.5),
		eyes = {
			{
				center = Vector3.new(6.6297, -39.9194, 53.2258),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(3.6593, 3.9919),
			},
			{
				center = Vector3.new(-6.6297, -39.9194, 53.2258),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(3.6593, 3.9919),
			},
		},
	},
	-- assets/blender/zorro_v2/e4_rig.blend
	ZorroDeAguaE4 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-143.2581, -90.4839, 0),
		boundsMax = Vector3.new(143.2581, 196.9355, 165),
		eyes = {
			{
				center = Vector3.new(13.2594, -74.5161, 95.8064),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(7.3185, 7.9839),
			},
			{
				center = Vector3.new(-13.2594, -74.5161, 95.8064),
				normal = Vector3.new(0, -1, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(7.3185, 7.9839),
			},
		},
	},
	-- assets/blender/orca_v2/e1_rig.blend
	OrcaE1 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-9.0484, -13.3065, 0),
		boundsMax = Vector3.new(9.0484, 13.2779, 16.5),
		requiresBone = "OjoIzqMira",
		eyes = {
			{
				center = Vector3.new(4.9104, -9.9929, 9.5474),
				normal = Vector3.new(0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(2.4617, 2.0625),
			},
			{
				center = Vector3.new(-4.9104, -9.9929, 9.5474),
				normal = Vector3.new(-0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(2.4617, 2.0625),
			},
		},
	},
	-- assets/blender/orca_v2/e2_rig.blend
	OrcaE2 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-28.2857, -42.4286, 0),
		boundsMax = Vector3.new(28.2857, 42.3442, 44),
		requiresBone = "OjoIzqMira",
		eyes = {
			{
				center = Vector3.new(10.9813, -37.733, 21.2143),
				normal = Vector3.new(0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(4.125, 4.3214),
			},
			{
				center = Vector3.new(-10.9813, -37.733, 21.2143),
				normal = Vector3.new(-0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(4.125, 4.3214),
			},
		},
	},
	-- assets/blender/orca_v2/e3_rig.blend
	OrcaE3 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-45.2419, -82.5, 0),
		boundsMax = Vector3.new(45.2419, 87.6798, 82.5),
		requiresBone = "OjoIzqMira",
		eyes = {
			{
				center = Vector3.new(18.5973, -74.5479, 34.5968),
				normal = Vector3.new(0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(6.3206, 5.3226),
			},
			{
				center = Vector3.new(-18.5973, -74.5479, 34.5968),
				normal = Vector3.new(-0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(6.3206, 5.3226),
			},
		},
	},
	-- assets/blender/orca_v2/e4_rig.blend
	OrcaE4 = {
		bone = "Cabeza",
		boundsMin = Vector3.new(-111.4886, -159.6774, 0),
		boundsMax = Vector3.new(111.4886, 175.6452, 165),
		requiresBone = "OjoIzqMira",
		eyes = {
			{
				center = Vector3.new(39.3116, -141.6561, 83.451),
				normal = Vector3.new(0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(7.9839, 7.9839),
			},
			{
				center = Vector3.new(-39.3116, -141.6561, 83.451),
				normal = Vector3.new(-0.7071, -0.7071, 0),
				up = Vector3.new(0, 0, 1),
				size = Vector2.new(7.9839, 7.9839),
			},
		},
	},
}

return data
