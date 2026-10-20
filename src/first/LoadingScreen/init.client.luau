--!strict
--[[
	LoadingScreen (ReplicatedFirst)

	La pantalla de carga al entrar: la isla con los gigantes de bloques, el título
	dorado y una barra de lava con porcentaje que sigue la carga real
	(LoadingProgress). Corre en ReplicatedFirst para quitar la de Roblox apenas
	llega y cubrir el resto: el mundo, las imágenes y sonidos, el personaje y el
	guardado. Se va cuando todo cargó y pasó Look.minSeconds, al tocar SALTAR
	(aparece a los Look.skipAfter) o a los Look.maxSeconds pase lo que pase.

	Antes de que llegue ReplicatedStorage solo espera sus dos módulos sin require
	(Assets/Loading y UIConfig/Loading); el resto de Shared lo pide LoadingProgress
	después de game.Loaded.
]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
shared:WaitForChild("Assets"):WaitForChild("Loading")
shared:WaitForChild("UIConfig"):WaitForChild("Loading")

local Look = require(ReplicatedStorage.Shared.UIConfig.Loading)
local LoadingFx = require(script.LoadingFx)
local LoadingProgress = require(script.LoadingProgress)
local LoadingView = require(script.LoadingView)

local SETTLE_SECONDS = 0.35 -- la barra llena se queda un momento antes del fundido

local player = Players.LocalPlayer
local view = LoadingView.build(player:WaitForChild("PlayerGui") :: PlayerGui)
ReplicatedFirst:RemoveDefaultLoadingScreen()

local fx = LoadingFx.start(view)
local progress = LoadingProgress.start(function(phase: LoadingProgress.Phase)
	fx.setStatus(Look.status[phase])
end)

local skipped = false
view.skip.Activated:Once(function()
	skipped = true
end)

local started = os.clock()
local skipShown = false
while true do
	local elapsed = os.clock() - started
	fx.setTarget(progress.fraction(elapsed))
	if not skipShown and elapsed >= Look.skipAfter then
		skipShown = true
		fx.showSkip()
	end
	local ready = progress.done() and elapsed >= Look.minSeconds
	if skipped or ready or elapsed >= Look.maxSeconds then
		break
	end
	task.wait()
end

view.skip.Visible = false
fx.setTarget(1)
fx.setStatus(Look.status.done)
if not skipped then
	while not fx.filled() do
		task.wait()
	end
	task.wait(SETTLE_SECONDS)
end
fx.fadeOut()
fx.stop()
view.gui:Destroy()
