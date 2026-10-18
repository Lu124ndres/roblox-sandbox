--!strict
--[[
	ToastBanner

	Tarjeta grande de los momentos importantes (pez nuevo, logro, evolución...).
	Va en la pila de avisos, arriba y debajo del panel de hambre, así nunca tapa
	al jugador ni su cartel. Cae desde arriba con rebote, un brillo la cruza,
	saltan chispas en las esquinas y el ícono gira sobre rayos de su color.
	El fondo es una placa de pizarra (Interface/Kit) teñida apenas de su color.
	Se desvanece entera (CanvasGroup) y se borra sola.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Interface.Kit)
local Style = require(script.Parent.Interface.Style)
local ToastFx = require(script.Parent.ToastFx)

local TWEENS = UIConfig.Tweens
local HEIGHT = 64
local WHITE = Color3.new(1, 1, 1)
local SLICE = 0.4 -- borde de la pizarra (la tarjeta es más baja que una ventana)
local TINT = 0.55 -- cuánto se acerca el color del aviso al blanco para teñir la piedra

local ToastBanner = {}

local function tween(target: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local run = TweenService:Create(target, info, goal)
	run:Play()
	return run
end

local function body(holder: Frame, color: Color3): CanvasGroup
	local group = Instance.new("CanvasGroup")
	group.Name = "Cuerpo"
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromScale(1, 1)
	group.Parent = holder
	local card = Instance.new("Frame")
	card.Name = "Fondo"
	card.Position = UDim2.fromOffset(3, 3)
	card.Size = UDim2.new(1, -6, 1, -6)
	Kit.skin(card, "panel", color:Lerp(WHITE, TINT)).SliceScale = SLICE
	card.Parent = group
	return group
end

-- Crea la tarjeta en `stack` y la borra sola a los `seconds`.
function ToastBanner.show(
	stack: Frame,
	order: number,
	text: string,
	color: Color3,
	seconds: number,
	icon: string?,
	caption: string?
): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Banner"
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Size = UDim2.new(1, 0, 0, HEIGHT)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(560, HEIGHT)
	limit.Parent = holder
	holder.Parent = stack
	local group = body(holder, color)
	local left = if icon then HEIGHT + 10 else 16
	if icon then
		ToastFx.badge(group, color, icon, HEIGHT)
	end
	local top = 0.12
	if caption then
		local small = Style.text(group, "Detalle", 20, color:Lerp(WHITE, 0.6), 2)
		small.Text = caption
		small.Position = UDim2.new(0, left, 0.1, 0)
		small.Size = UDim2.new(1, -left - 14, 0.32, 0)
		small.ZIndex = 4
		top = 0.38
	end
	local title = Style.text(group, "Texto", 34, WHITE, 3)
	title.Text = text
	title.Position = UDim2.new(0, left, top, 0)
	title.Size = UDim2.new(1, -left - 14, if caption then 0.54 else 0.76, 0)
	title.ZIndex = 4
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(WHITE, color:Lerp(WHITE, 0.35))
	fill.Parent = title
	if icon then
		for _, child in group:GetChildren() do
			if child:IsA("TextLabel") then
				child.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
	end
	ToastFx.shine(group)
	ToastFx.sparkles(holder, color)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.5
	scale.Parent = holder
	group.Position = UDim2.fromOffset(0, -24)
	group.GroupTransparency = 1
	tween(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 })
	tween(
		group,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{ Position = UDim2.new(), GroupTransparency = 0 }
	)
	task.delay(seconds, function()
		if holder.Parent then
			tween(
				group,
				TWEENS.Fade,
				{ GroupTransparency = 1, Position = UDim2.fromOffset(0, -16) }
			).Completed:Wait()
			holder:Destroy()
		end
	end)
	return holder
end

return ToastBanner
