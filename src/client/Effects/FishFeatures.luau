--!strict
--[[
	FishFeatures

	Piezas de primitivas para los peces de FishModel: la pieza base, los
	óvalos (cuerpo, panza, bandas) y los rasgos propios de cada especie
	(rayas, púas, espada, farolito...). Todo en coordenadas del pez: mira
	hacia -Z, la cola está en +Z y el centro del cuerpo es el origen.
]]

local FishShapes = require(script.Parent.FishShapes)

local FishFeatures = {}

function FishFeatures.part(
	model: Model,
	name: string,
	size: Vector3,
	color: Color3,
	cframe: CFrame
): Part
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.Color = color
	piece.Material = Enum.Material.SmoothPlastic
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	piece.CFrame = cframe
	piece.Parent = model
	return piece
end

-- Óvalo: una pieza con malla de esfera estirada (no tiene que ser cúbica).
function FishFeatures.oval(
	model: Model,
	name: string,
	scale: Vector3,
	color: Color3,
	cframe: CFrame
): BasePart
	local piece = FishFeatures.part(model, name, Vector3.one, color, cframe)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = scale
	mesh.Parent = piece
	return piece
end

function FishFeatures.fin(
	model: Model,
	name: string,
	size: Vector3,
	color: Color3,
	cframe: CFrame
): BasePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.Color = color
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Anchored = true
	wedge.CanCollide = false
	wedge.CanQuery = false
	wedge.CanTouch = false
	wedge.CastShadow = false
	wedge.CFrame = cframe
	wedge.Parent = model
	return wedge
end

-- Rasgos propios de la especie. s = tamaño del cuerpo ya escalado.
function FishFeatures.add(model: Model, shape: FishShapes.Shape, s: Vector3, scale: number)
	local stripes = shape.stripes
	if stripes then
		for k = 1, stripes.count do
			local t = k / (stripes.count + 1)
			if stripes.vertical then
				local z = (t - 0.5) * s.Z * 0.8
				local taper = math.sqrt(math.max(0.15, 1 - (2 * z / s.Z) ^ 2))
				local band = Vector3.new(s.X * 1.04 * taper, s.Y * 1.02 * taper, s.Z * 0.1)
				FishFeatures.oval(model, `Banda{k}`, band, stripes.color, CFrame.new(0, 0, z))
			else
				local z = (t - 0.5) * s.Z * 0.7
				local bar = Vector3.new(s.X * 0.7, s.Y * 0.1, s.Z * 0.14)
				local cframe = CFrame.new(0, s.Y * 0.4, z) * CFrame.Angles(0, math.rad(25), 0)
				FishFeatures.oval(model, `Raya{k}`, bar, stripes.color, cframe)
			end
		end
	end
	if shape.line then
		FishFeatures.oval(
			model,
			"Linea",
			Vector3.new(s.X * 1.03, s.Y * 0.1, s.Z * 0.85),
			shape.line,
			CFrame.new()
		)
	end
	if shape.spikes then
		local count = 18
		for k = 1, count do
			-- Puntos repartidos sobre una esfera (espiral de Fibonacci).
			local y = 1 - 2 * (k - 0.5) / count
			local ring = math.sqrt(1 - y * y)
			local angle = k * 2.399963
			local dir = Vector3.new(math.cos(angle) * ring, y, math.sin(angle) * ring)
			local surface = Vector3.new(dir.X * s.X, dir.Y * s.Y, dir.Z * s.Z) * 0.5
			local length = 0.32 * scale
			local spike = FishFeatures.part(
				model,
				`Pua{k}`,
				Vector3.new(0.07, 0.07, length) * scale,
				shape.spikes,
				CFrame.lookAt(surface, surface + dir) * CFrame.new(0, 0, -length / 2)
			)
			spike.Material = Enum.Material.Plastic
		end
	end
	if shape.finlets then
		for k = 1, 4 do
			local z = s.Z * (0.12 + k * 0.08)
			for side = -1, 1, 2 do
				local y = side * s.Y * (0.32 - k * 0.04)
				FishFeatures.part(
					model,
					`Aletita{k}{side}`,
					Vector3.new(0.05, 0.16, 0.14) * scale,
					shape.finlets,
					CFrame.new(0, y, z)
				)
			end
		end
	end
	if shape.sword then
		local length = shape.sword * scale
		local sword = FishFeatures.part(
			model,
			"Espada",
			Vector3.new(0.12 * scale, 0.1 * scale, length),
			Color3.fromRGB(190, 198, 210),
			CFrame.new(0, s.Y * 0.05, -s.Z * 0.45 - length / 2)
		)
		sword.Material = Enum.Material.Metal
	end
	if shape.lure then
		local tip = Vector3.new(0, s.Y * 0.85, -s.Z * 0.8)
		local base = Vector3.new(0, s.Y * 0.45, -s.Z * 0.3)
		local stalk = FishFeatures.part(
			model,
			"Antena",
			Vector3.new(0.05, 0.05, (tip - base).Magnitude) * Vector3.new(scale, scale, 1),
			shape.body,
			CFrame.lookAt((tip + base) / 2, tip)
		)
		stalk.Material = Enum.Material.Plastic
		local bulb = FishFeatures.part(
			model,
			"Farolito",
			Vector3.one * 0.32 * scale,
			shape.lure,
			CFrame.new(tip)
		)
		bulb.Shape = Enum.PartType.Ball
		bulb.Material = Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Color = shape.lure
		light.Range = 10 * scale
		light.Brightness = 2
		light.Parent = bulb
		for k = -2, 2 do -- dientes
			local tooth = FishFeatures.fin(
				model,
				`Diente{k}`,
				Vector3.new(0.05, 0.14, 0.08) * scale,
				Color3.fromRGB(245, 245, 235),
				CFrame.new(k * s.X * 0.09, -s.Y * 0.08, -s.Z * 0.47) * CFrame.Angles(math.pi, 0, 0)
			)
			tooth.Material = Enum.Material.Plastic
		end
	end
end

return FishFeatures
