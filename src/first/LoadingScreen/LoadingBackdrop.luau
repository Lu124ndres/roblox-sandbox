--!strict
--[[
	LoadingBackdrop

	El fondo de la pantalla de carga: se pide primero y aparece apenas llega (la
	señal de IsLoaded no avisa siempre: la imagen quedaba invisible), siempre cubre
	la pantalla sin deformarse y se acerca y aleja despacio (Ken Burns).

	No usa ScaleType.Crop porque ese recorta centrado: en pantallas anchas se comía
	el cielo, y el dragón que vuela arriba quedaba afuera. Aquí el tamaño se calcula
	cada cuadro y el punto FOCUS de la imagen queda fijo en el mismo punto de la
	pantalla, así se recorta más el agua de abajo que el cielo.
		start(fondo, raiz) -> Backdrop
		backdrop.leave()   se acerca rápido (el fundido de salida)
		backdrop.stop()
]]

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Backdrop = { leave: () -> (), stop: () -> () }

local ASPECT = 16 / 9 -- assets/ui/carga/fondo.png
local FOCUS = Vector2.new(0.5, 0.3)
local ZOOM_MIN, ZOOM_MAX = 1.04, 1.14
local ZOOM_SECONDS = 30 -- ida y vuelta del acercamiento
local LEAVE_ZOOM = 0.35 -- cuánto se acerca por segundo al salir

local LoadingBackdrop = {}

function LoadingBackdrop.start(background: ImageLabel, root: GuiObject): Backdrop
	background.ScaleType = Enum.ScaleType.Stretch
	background.AnchorPoint = FOCUS
	background.Position = UDim2.fromScale(FOCUS.X, FOCUS.Y)

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ background })
		end)
		if background.Parent then
			TweenService:Create(background, TweenInfo.new(0.8), { ImageTransparency = 0 }):Play()
		end
	end)

	local clock, leaving = 0, 0
	local isLeaving = false
	local connection = RunService.RenderStepped:Connect(function(dt: number)
		clock += dt
		if isLeaving then
			leaving += dt
		end
		local wave = 0.5 - 0.5 * math.cos(clock * 2 * math.pi / ZOOM_SECONDS)
		local zoom = ZOOM_MIN + (ZOOM_MAX - ZOOM_MIN) * wave + leaving * LEAVE_ZOOM
		local screen = root.AbsoluteSize
		-- Cubrir: la imagen mide lo justo para tapar el lado que más le cuesta.
		local width = math.max(screen.X, screen.Y * ASPECT) * zoom
		background.Size = UDim2.fromOffset(width, width / ASPECT)
		-- Un vaivén lateral leve acompaña al acercamiento.
		background.Position =
			UDim2.new(FOCUS.X, math.sin(clock * 0.2) * screen.X * 0.01, FOCUS.Y, 0)
	end)

	return {
		leave = function()
			isLeaving = true
		end,
		stop = function()
			connection:Disconnect()
		end,
	}
end

return table.freeze(LoadingBackdrop)
