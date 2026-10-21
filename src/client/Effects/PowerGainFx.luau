--!strict
--[[
	PowerGainFx

	Lo que se ve en la pantalla mientras entrenas (cada TrainingTick):
		· Cristalitos de energía que aparecen en distintos puntos de la pantalla
		  y vuelan en curva hasta el contador de poder (pocos por tick y con
		  tope, para que nunca tapen el juego).
		· Un brillo azul suave en los bordes de toda la pantalla (viñeta) mientras
		  sigan llegando ticks; se apaga solo al dejar de entrenar.
		· "+1.6M" junto al contador que va sumando lo ganado en los últimos
		  segundos (un solo número, no una lluvia de textos).
	Con "efectos reducidos" salen menos cristales por tick.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Device = require(script.Parent.Parent.Interface.Device)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)
local PowerGainParts = require(script.Parent.PowerGainParts)

local LIGHT = Color3.fromRGB(215, 240, 255)
local ORBS_PER_TICK, MAX_ORBS = 4, 16
local FLY_SECONDS = 0.75
local EDGE_ON, EDGE_PULSE = 0.35, 0.6 -- transparencia de la viñeta (1 = invisible)
local EDGE_TOUCH = 0.2 -- en el teléfono, más suave (la pantalla es chica)
local IDLE_SECONDS = 1.4 -- sin ticks este tiempo: se apaga el marco y se borra la suma

type Orb = { frame: Frame, scale: UIScale, from: Vector2, bend: Vector2, born: number }

local PowerGainFx = {}

local rng = Random.new()
local screenGui: ScreenGui? = nil
local vignette: ImageLabel? = nil
local orbs: { Orb } = {}
local sumLabel: TextLabel? = nil
local sumScale: UIScale? = nil
local target: GuiObject? = nil
local sum, lastTick = 0, 0

local function goal(screen: ScreenGui): Vector2
	local label = target
	if not label then
		return screen.AbsoluteSize * Vector2.new(0.08, 0.4)
	end
	return label.AbsolutePosition
		+ label.AbsoluteSize * Vector2.new(0.12, 0.5)
		- screen.AbsolutePosition
end

local function spawnOrb(screen: ScreenGui, delay: number)
	if #orbs >= MAX_ORBS then
		return
	end
	local size = screen.AbsoluteSize
	-- Por toda la pantalla, pero lejos del contador (si no, no se ve el vuelo).
	local from = size * Vector2.new(rng:NextNumber(0.3, 0.9), rng:NextNumber(0.15, 0.85))
	local frame, scale = PowerGainParts.orb(screen)
	local side = math.clamp(size.Y * 0.05, 36, 72) -- proporcional a la pantalla
	frame.Size = UDim2.fromOffset(side, side)
	frame.Position = UDim2.fromOffset(from.X, from.Y)
	local bend = Vector2.new(rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.35, -0.1)) * size.Y
	table.insert(
		orbs,
		{ frame = frame, scale = scale, from = from, bend = bend, born = os.clock() + delay }
	)
end

local function step()
	local screen = screenGui
	if not screen then
		return
	end
	local now = os.clock()
	local finish = goal(screen)
	for index = #orbs, 1, -1 do
		local orb = orbs[index]
		local age = now - orb.born
		if age >= 0 then
			local appear = math.clamp(age / 0.18, 0, 1)
			local t = math.clamp((age - 0.18) / FLY_SECONDS, 0, 1)
			local e = t * t -- acelera hacia el contador
			local control = (orb.from + finish) / 2 + orb.bend
			local p = (1 - e) ^ 2 * orb.from + 2 * (1 - e) * e * control + e ^ 2 * finish
			orb.frame.Position = UDim2.fromOffset(p.X, p.Y)
			orb.scale.Scale = appear * (1 - 0.55 * e)
			if t >= 1 then
				orb.frame:Destroy()
				table.remove(orbs, index)
			end
		end
	end
	if now - lastTick > IDLE_SECONDS and sum > 0 then
		sum = 0
		local label = sumLabel
		if label then
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			local stroke = label:FindFirstChildOfClass("UIStroke")
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			end
		end
		if vignette then
			TweenService:Create(vignette, TweenInfo.new(0.6), { ImageTransparency = 1 }):Play()
		end
	end
end

function PowerGainFx.mount(screen: ScreenGui)
	screenGui = screen
	local playerGui = screen.Parent
	if playerGui then
		vignette = PowerGainParts.vignette(playerGui)
	end
	task.spawn(function()
		local row = Layout.stats():WaitForChild("Stat2", 30)
		local value = row and row:WaitForChild("Valor", 10)
		if not (row and value and value:IsA("GuiObject")) then
			return
		end
		target = value
		local label = Style.text(row, "Ganancia", 26, LIGHT, 2.5)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.new(1, 6, 0.5, 0)
		label.Size = UDim2.fromOffset(150, 28)
		label.TextTransparency = 1
		local stroke = label:FindFirstChildOfClass("UIStroke") :: UIStroke
		stroke.Color = Color3.fromRGB(15, 50, 110)
		stroke.Transparency = 1
		local scale = Instance.new("UIScale")
		scale.Parent = label
		sumLabel, sumScale = label, scale
	end)
	RunService.RenderStepped:Connect(step)
end

-- Un tick de entrenamiento: `gained` poder.
function PowerGainFx.gain(gained: number)
	local screen = screenGui
	if not screen then
		return
	end
	lastTick = os.clock()
	sum += gained
	-- Con efectos reducidos, menos cristales (el marco es barato: se queda).
	local low = ClientSettings.get("lowFx")
	for k = 1, if low then 2 else ORBS_PER_TICK do
		spawnOrb(screen, (k - 1) * 0.08)
	end
	local glow = vignette
	if glow then
		local soft = if Device.touch() then EDGE_TOUCH else 0
		glow.ImageTransparency = EDGE_ON + soft
		TweenService:Create(glow, TweenInfo.new(0.5), { ImageTransparency = EDGE_PULSE + soft })
			:Play()
	end
	local label, scale = sumLabel, sumScale
	if label and scale then
		label.Text = `+{NumberFormat.short(sum)}`
		label.TextTransparency = 0
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
		scale.Scale = 1.2
		TweenService:Create(scale, UIConfig.Tweens.Pop, { Scale = 1 }):Play()
	end
end

return PowerGainFx
