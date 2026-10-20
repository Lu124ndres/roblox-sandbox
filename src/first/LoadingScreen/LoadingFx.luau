--!strict
--[[
	LoadingFx

	Da vida a la pantalla de carga que armó LoadingView. Todo por código:
	- el fondo aparece apenas llega y se acerca despacio (LoadingBackdrop)
	- el título entra con un rebote, flota y su dorado brilla
	- chispas de lava cuadradas (como los gigantes, todo bloques) suben desde abajo
	- la barra se llena suave hacia la meta, con un destello que la cruza, y el pez
	  nada sobre la punta meneándose
	- el consejo cambia cada Look.tipSeconds con un fundido
		start(view) -> Fx
		fx.setTarget(0..1)   hasta dónde debe llegar la barra (nunca retrocede)
		fx.setStatus(texto)
		fx.showSkip()
		fx.filled() -> boolean   la barra ya llegó al 100 %
		fx.fadeOut() -> ()       fundido de salida (cede hasta que termina)
		fx.stop()                corta todo (las instancias las borra el dueño de la vista)
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Look = require(ReplicatedStorage.Shared.UIConfig.Loading)
local LoadingBackdrop = require(script.Parent.LoadingBackdrop)
local LoadingParts = require(script.Parent.LoadingParts)
local LoadingView = require(script.Parent.LoadingView)

export type Fx = {
	setTarget: (fraction: number) -> (),
	setStatus: (text: string) -> (),
	showSkip: () -> (),
	filled: () -> boolean,
	fadeOut: () -> (),
	stop: () -> (),
}

local COLORS = Look.colors
local SINE = Enum.EasingStyle.Sine
local IN_OUT = Enum.EasingDirection.InOut
local FOREVER = -1
local SHINE_SECONDS = 1.6

local function tween(target: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local playing = TweenService:Create(target, info, goal)
	playing:Play()
	return playing
end

local function popIn(target: GuiObject, seconds: number)
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = target
	tween(
		scale,
		TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
end

-- Una chispa cuadrada que sube girando y se apaga.
local function ember(layer: Frame, onGone: () -> ())
	local size = math.random(4, 11)
	local spark = Instance.new("Frame")
	spark.BorderSizePixel = 0
	spark.BackgroundColor3 = COLORS.Ember:Lerp(COLORS.EmberHot, math.random())
	spark.AnchorPoint = Vector2.new(0.5, 0.5)
	local x = math.random()
	spark.Position = UDim2.new(x, 0, 1, size)
	spark.Size = UDim2.fromOffset(size, size)
	spark.Rotation = math.random(0, 90)
	spark.ZIndex = layer.ZIndex
	spark.Parent = layer
	local seconds = 3 + math.random() * 2.5
	local rise =
		tween(spark, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.12, 0.3 + math.random() * 0.4),
			Rotation = spark.Rotation + math.random(180, 400),
			BackgroundTransparency = 1,
		})
	rise.Completed:Once(function()
		spark:Destroy()
		onGone()
	end)
end

local LoadingFx = {}

function LoadingFx.start(view: LoadingView.View): Fx
	local connections: { RBXScriptConnection } = {}
	local target, shown = 0, 0
	local embers, emberClock, tipClock, clock = 0, 0, 0, 0
	local tipIndex = math.random(1, #Look.tips)

	view.tip.Text = Look.tips[tipIndex]
	popIn(view.title, 0.7)
	tween(view.title, TweenInfo.new(1.8, SINE, IN_OUT, FOREVER, true), {
		Position = view.title.Position + UDim2.fromScale(0, 0.015),
	})
	local backdrop = LoadingBackdrop.start(view.background, view.root)

	local function nextTip()
		local stroke = view.tip:FindFirstChildOfClass("UIStroke") :: UIStroke
		local fade = TweenInfo.new(0.25)
		tween(stroke, fade, { Transparency = 1 })
		tween(view.tip, fade, { TextTransparency = 1 }).Completed:Once(function()
			tipIndex = tipIndex % #Look.tips + 1
			view.tip.Text = Look.tips[tipIndex]
			tween(stroke, fade, { Transparency = 0 })
			tween(view.tip, fade, { TextTransparency = 0 })
		end)
	end

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(dt: number)
			clock += dt
			-- Barra: se acerca rápido a la meta pero nunca más de fillSpeed por segundo.
			local step = math.min((target - shown) * math.min(1, dt * 4), Look.fillSpeed * dt)
			shown = math.clamp(shown + math.max(step, 0), 0, 1)
			view.fill.Size = UDim2.fromScale(shown, 1)
			view.percent.Text = `{math.floor(shown * 100 + 0.5)}%`
			view.fish.Position = UDim2.new(shown, 0, 0, -4 + math.sin(clock * 5) * 3)
			view.fish.Rotation = math.sin(clock * 7) * 8
			local width = view.fill.AbsoluteSize.X
			local phase = (clock % SHINE_SECONDS) / SHINE_SECONDS
			view.shine.Position = UDim2.new(0, -40 + (width + 80) * phase, 0.5, 0)
			view.titleGradient.Offset = Vector2.new(0, math.sin(clock * 1.6) * 0.18)

			emberClock += dt
			if emberClock >= Look.emberEvery then
				emberClock = 0
				if embers < Look.emberMax then
					embers += 1
					ember(view.embers, function()
						embers -= 1
					end)
				end
			end
			tipClock += dt
			if tipClock >= Look.tipSeconds then
				tipClock = 0
				nextTip()
			end
		end)
	)

	local fx: Fx
	fx = {
		setTarget = function(fraction: number)
			target = math.max(target, math.clamp(fraction, 0, 1))
		end,
		setStatus = function(text: string)
			view.status.Text = text
		end,
		showSkip = function()
			view.skip.Visible = true
			popIn(view.skip, 0.45)
		end,
		filled = function(): boolean
			return shown >= 0.999
		end,
		fadeOut = function()
			backdrop.leave()
			LoadingParts.fadeAll(view.root, Look.fadeSeconds)
			task.wait(Look.fadeSeconds)
		end,
		stop = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			backdrop.stop()
		end,
	}
	return fx
end

return table.freeze(LoadingFx)
