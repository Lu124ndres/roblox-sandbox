--!strict
--[[
	BoostTimer

	Cartel arriba de la columna derecha mientras dura el entrenamiento que alguien
	compró para todo el servidor: cuánto multiplica, quién fue y cuánto queda.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Ui = require(script.Parent.Parent.Ui)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local REFRESH_SECONDS = 0.5

local BoostTimer = {}

function BoostTimer.start(_screen: ScreenGui)
	-- Arriba de la columna derecha (encima de Tienda y Robux).
	local pill = Ui.panel("ImpulsoServidor", Layout.right())
	pill.LayoutOrder = 1
	pill.Size = UDim2.fromOffset(220, 54)
	Style.border(pill, 3)
	pill.BackgroundColor3 = UIConfig.Colors.Robux
	pill.BackgroundTransparency = 0.1
	pill.Visible = false
	local title = Ui.label("Texto", pill, UIConfig.Fonts.Title, UIConfig.TextSizes.Body)
	title.Position = UDim2.fromOffset(8, 4)
	title.Size = UDim2.new(1, -16, 0, 26)
	local by = Ui.label("Comprador", pill, UIConfig.Fonts.Body, UIConfig.TextSizes.Small)
	by.Position = UDim2.fromOffset(8, 30)
	by.Size = UDim2.new(1, -16, 0, 18)

	local folder = ReplicatedStorage:WaitForChild(Protocol.BoostFolder)
	task.spawn(function()
		while true do
			local left = Perks.serverBoostSeconds()
			pill.Visible = left > 0
			if left > 0 then
				local total = math.ceil(left)
				title.Text = `x{2 ^ Perks.serverBoostLevel()} Entrenamiento · {string.format(
					"%d:%02d",
					total // 60,
					total % 60
				)}`
				local buyer = folder:GetAttribute(Protocol.BoostAttributes.BoughtBy)
				by.Text = if type(buyer) == "string" and buyer ~= ""
					then `Gracias a {buyer}`
					else ""
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return BoostTimer
