--!strict
--[[
	HabitatFx

	Los efectos locales de los props del hábitat (Workspace.Habitat, lo arma
	server/World/HabitatService), según el atributo Efecto de cada uno:
		"fuego"   un Fire en el punto Llama, escalado con el prop (atributo Escala).
		          En modo rápido (ajuste lowFx) no se crea, y se quita al activarlo.
		"brillo"  las partes Neon laten suave (se vuelven un poco transparentes y
		          vuelven), cada prop con su propio desfase.
	La luz ("luz", y la del fuego) la pone el servidor: se ve igual para todos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local FIRE = Config.Habitats.fire
local GLOW = Config.Habitats.glow

local HabitatFx = {}

-- Fuego de cada prop "fuego" (la pieza invisible que lo sostiene).
local fires: { [Model]: BasePart } = {}
-- Partes Neon que laten, con su desfase (0..1 de vuelta).
local glowing: { [BasePart]: number } = {}
local rng = Random.new()

local function addFire(model: Model)
	if fires[model] or ClientSettings.get("lowFx") then
		return
	end
	local root = model.PrimaryPart
	if not root then
		return
	end
	local anchor = root:FindFirstChild("Llama")
	local scale = model:GetAttribute("Escala")
	local size = FIRE.size * (if type(scale) == "number" then scale else 1)
	local holder = Instance.new("Part")
	holder.Name = "Fuego"
	holder.Size = Vector3.one
	holder.CFrame = if anchor and anchor:IsA("Attachment") then anchor.WorldCFrame else root.CFrame
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	local fire = Instance.new("Fire")
	fire.Size = size
	fire.Heat = FIRE.heat
	fire.Color = FIRE.color
	fire.SecondaryColor = FIRE.secondaryColor
	fire.Parent = holder
	holder.Parent = model
	fires[model] = holder
end

local function removeFires()
	for model, holder in fires do
		holder:Destroy()
		fires[model] = nil
	end
end

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local effect = model:GetAttribute("Efecto")
	if effect == "fuego" then
		addFire(model)
	elseif effect == "brillo" then
		local phase = rng:NextNumber()
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
				glowing[part] = phase
			end
		end
	end
end

local function pulse()
	local turn = os.clock() / GLOW.seconds
	for part, phase in glowing do
		if not part.Parent then
			glowing[part] = nil
			continue
		end
		local wave = 0.5 - 0.5 * math.cos((turn + phase) * 2 * math.pi)
		part.Transparency = GLOW.transparency * wave
	end
end

function HabitatFx.start()
	task.spawn(function()
		-- El servidor la crea después del terreno (unos segundos): sin plazo y sin aviso.
		local folder = Workspace:WaitForChild(Protocol.Map.Habitat, math.huge) :: Folder
		folder.ChildAdded:Connect(track)
		folder.ChildRemoved:Connect(function(child: Instance)
			if child:IsA("Model") then
				fires[child] = nil
			end
		end)
		for _, child in folder:GetChildren() do
			track(child)
		end
		ClientSettings.onChanged(function(key: string, low: boolean)
			if key ~= "lowFx" then
				return
			end
			if low then
				removeFires()
			else
				for _, child in folder:GetChildren() do
					if child:IsA("Model") and child:GetAttribute("Efecto") == "fuego" then
						addFire(child)
					end
				end
			end
		end)
		RunService.Heartbeat:Connect(pulse)
	end)
end

return HabitatFx
