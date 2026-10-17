--!strict
--[[
	Dragon/Medidas

	Lo que Dragon/Rig mide del modelo al enlazarlo para que el dragón pueda
	posarse (Dragon/Patas, Dragon/Posado), igual con los modelos de ahora y con
	los v2 (mismos 32 huesos y nombres):
		legRest   el ángulo de cada hueso de las patas en reposo, de costado
		          (0 = hacia abajo, + = hacia adelante); la mano y el pie, el del
		          hueso anterior (no tienen hijo)
		contacts  dónde apoya cada pata (planta y garras, algo detrás y debajo del
		          tobillo) y la panza bajo el pecho y la cadera, en el espacio del
		          hueso y en largos de pierna (CONTACTS: medido en las mallas de los
		          modelos E1 y E4 con tools/blender)
		feet      cuánto detrás de la raíz queda el centro de las patas (en largos
		          de pierna)
		shin      el largo de la pierna (para seguir los ScaleTo)
	forward y up: ejes del cuerpo en el espacio del pivote.
]]

local LEGS = {
	BrazoIzq = "AntebrazoIzq",
	AntebrazoIzq = "ManoIzq",
	BrazoDer = "AntebrazoDer",
	AntebrazoDer = "ManoDer",
	MusloIzq = "PiernaIzq",
	PiernaIzq = "PieIzq",
	MusloDer = "PiernaDer",
	PiernaDer = "PieDer",
}
-- Apoyo: hueso -> (atrás, abajo) en largos de pierna, con el cuerpo en reposo.
local CONTACTS = {
	PieIzq = Vector2.new(0.8, 0.65),
	PieDer = Vector2.new(0.8, 0.65),
	ManoIzq = Vector2.new(0.25, 0.3),
	ManoDer = Vector2.new(0.25, 0.3),
	Pecho = Vector2.new(0, 0.6),
	Cadera = Vector2.new(0, 0.55),
}

export type Medidas = {
	legRest: { [string]: number },
	contacts: { [string]: Vector3 },
	feet: number,
	shin: number,
}

local Medidas = {}

function Medidas.measure(
	bones: { [string]: Bone },
	pivot: CFrame,
	forward: Vector3,
	up: Vector3
): Medidas
	local function at(bone: Bone): Vector3
		return pivot:PointToObjectSpace(bone.WorldPosition)
	end
	local legRest: { [string]: number } = {}
	for name, child in LEGS do
		if bones[name] and bones[child] then
			local d = at(bones[child]) - at(bones[name])
			legRest[name] = math.atan2(d:Dot(forward), -d:Dot(up))
		end
	end
	for _, s in { "Izq", "Der" } do -- el pie y la mano siguen al hueso de antes
		legRest[`Pie{s}`] = legRest[`Pierna{s}`]
		legRest[`Mano{s}`] = legRest[`Antebrazo{s}`]
	end
	local shinBone = bones.PieIzq or bones.PieDer
	local shin = if shinBone then math.max(shinBone.CFrame.Position.Magnitude, 1e-3) else 1
	local back, down = pivot:VectorToWorldSpace(-forward), pivot:VectorToWorldSpace(-up)
	local contacts: { [string]: Vector3 } = {}
	local feetSum, feetCount = 0, 0
	for name, k in CONTACTS do
		local bone = bones[name]
		if bone then
			local world = bone.WorldPosition + (back * k.X + down * k.Y) * shin
			contacts[name] = bone.WorldCFrame:PointToObjectSpace(world) / shin
			if name ~= "Pecho" and name ~= "Cadera" and bones.Raiz then
				feetSum += (pivot:PointToObjectSpace(world) - at(bones.Raiz)):Dot(forward)
				feetCount += 1
			end
		end
	end
	return {
		legRest = legRest,
		contacts = contacts,
		feet = if feetCount > 0 then -feetSum / feetCount / shin else 0,
		shin = shin,
	}
end

return table.freeze(Medidas)
