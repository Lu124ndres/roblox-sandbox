--!strict
--[[
	Squash

	Estirar y aplastar un modelo de primitivas (los peces): se estira a lo
	largo de su eje Z (el largo del pez) conservando el volumen, como en
	los dibujos animados: largo y finito cuando va rápido, chato y ancho al
	chocar.

	Solo cambia la Scale de las mallas (los óvalos con SpecialMesh) y la
	posición de cada pieza; las piezas sin malla (ojos, aletas) solo se
	acomodan. Nada de tocar Size: no despierta la física. La pose de reposo
	de cada modelo se guarda la primera vez (sin estirar) y sirve aunque el
	modelo se reutilice (FeedPool).
]]

local Workspace = game:GetService("Workspace")

type Piece = { part: BasePart, offset: CFrame, mesh: SpecialMesh?, scale: Vector3 }

local Squash = {}

local rests: { [Model]: { Piece } } = setmetatable({} :: any, { __mode = "k" })

local function capture(model: Model): { Piece }
	local pivot = model:GetPivot()
	local pieces: { Piece } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local mesh = descendant:FindFirstChildOfClass("SpecialMesh")
			table.insert(pieces, {
				part = descendant,
				offset = pivot:ToObjectSpace(descendant.CFrame),
				mesh = mesh,
				scale = if mesh then mesh.Scale else Vector3.one,
			})
		end
	end
	return pieces
end

-- Coloca el modelo en `cframe` estirado `stretch` veces a lo largo (1 = normal).
function Squash.pivot(model: Model, cframe: CFrame, stretch: number)
	local pieces = rests[model]
	if not pieces then
		pieces = capture(model)
		rests[model] = pieces
	end
	local side = 1 / math.sqrt(math.max(stretch, 0.05))
	local axes = Vector3.new(side, side, stretch)
	local parts: { BasePart } = table.create(#pieces)
	local frames: { CFrame } = table.create(#pieces)
	for index, piece in pieces do
		local offset = piece.offset
		parts[index] = piece.part
		frames[index] = cframe * CFrame.new(offset.Position * axes) * offset.Rotation
		local mesh = piece.mesh
		if mesh then
			-- El estiramiento del modelo, visto desde los ejes de la pieza.
			local r = offset.Rotation
			local local3 = Vector3.new(
				(r.XVector * axes).Magnitude,
				(r.YVector * axes).Magnitude,
				(r.ZVector * axes).Magnitude
			)
			mesh.Scale = piece.scale * local3
		end
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

-- Estiramiento de un vuelo en arco en la fracción t: largo al salir y al
-- caer (va rápido), redondo arriba (casi quieto).
function Squash.arc(t: number, amount: number): number
	return 1 + amount * (math.abs(1 - 2 * t) - 0.35)
end

-- Aplastón al chocar que rebota y se apaga en ~0.35 s (elapsed en segundos).
function Squash.impact(elapsed: number, amount: number): number
	return 1 - amount * math.exp(-9 * elapsed) * math.cos(elapsed * 22)
end

return Squash
