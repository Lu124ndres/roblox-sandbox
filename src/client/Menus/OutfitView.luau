--!strict
--[[
	OutfitView

	Lo que muestra cada tarjeta de PERSONAJES (OutfitCard):
		perks     las dos líneas de ventajas, armadas con los números del pase
		portrait  el personaje en 3D (ViewportFrame) copiado de su vitrina del
		          mapa (Workspace.Vitrinas), de tres cuartos y de cuerpo entero,
		          saliendo un poco por arriba de la tarjeta
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Trajes = require(ReplicatedStorage.Shared.Trajes)

local OutfitView = {}

-- Las dos líneas de ventajas, a partir de los números del pase.
function OutfitView.perks(pass: any): { string }
	local lines = {}
	if pass.biteDelay then
		table.insert(lines, `Pican x{math.floor(1 / pass.biteDelay + 0.5)} más rápido`)
	end
	if pass.instantReel then
		table.insert(lines, "Sacas peces de un toque")
	elseif pass.reelStrength then
		table.insert(lines, `Recoges con x{pass.reelStrength} de fuerza`)
	end
	return lines
end

-- El personaje en 3D: copia de la vitrina, de tres cuartos y de cuerpo entero.
function OutfitView.portrait(card: Frame, passKey: string)
	local view = Instance.new("ViewportFrame")
	view.Name = "Personaje"
	view.BackgroundTransparency = 1
	view.Position = UDim2.new(0, -8, 0, -30)
	view.Size = UDim2.new(0.4, 0, 1, 8)
	view.ZIndex = 4
	view.Ambient = Color3.fromRGB(170, 170, 180)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-0.4, -1, -0.6)
	view.Parent = card
	task.spawn(function()
		local folder = Workspace:WaitForChild("Vitrinas", 60)
		local showcase = folder and folder:WaitForChild(passKey, 30)
		local sample = showcase and showcase:WaitForChild("Muestra", 30)
		if not sample or not sample:IsA("Model") then
			return
		end
		-- La vitrina llega por partes: espera la malla (con sus huesos) antes de copiar.
		local deadline = os.clock() + 30
		while not Trajes.mesh(sample) and os.clock() < deadline do
			task.wait(0.5)
		end
		local mesh = Trajes.mesh(sample)
		if not mesh or not view.Parent then
			return
		end
		local model = Instance.new("Model")
		local copy = mesh:Clone() -- solo el traje: sin auras ni luces
		-- De pie y mirando a la cámara (-Z), un poco girado: de tres cuartos.
		local facing = CFrame.Angles(0, math.rad(22), 0)
		local frame = Trajes.measure(mesh) -- de pie, mirando al frente (medido con los huesos)
		copy.CFrame = facing * frame:ToObjectSpace(mesh.CFrame)
		copy.Parent = model
		local box, size = model:GetBoundingBox()
		model.Parent = view
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		local distance = size.Y * 0.5 / math.tan(math.rad(15)) * 1.08
		local center = box.Position
		camera.CFrame = CFrame.lookAt(center + Vector3.new(0, size.Y * 0.04, -distance), center)
		camera.Parent = view
		view.CurrentCamera = camera
	end)
end

return table.freeze(OutfitView)
