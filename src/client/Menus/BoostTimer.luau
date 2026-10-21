--!strict
--[[
	BoostTimer

	Cartel arriba de la columna del menú mientras dura el entrenamiento que alguien
	compró para todo el servidor: cuánto multiplica, quién fue y cuánto queda.
	Es una placa de piedra verde (Interface/Kit) con texto blanco con contorno.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Perks = require(ReplicatedStorage.Shared.Perks)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Layout = require(script.Parent.Parent.Interface.Layout)
local Style = require(script.Parent.Parent.Interface.Style)

local REFRESH_SECONDS = 0.5

local BoostTimer = {}

function BoostTimer.start(_screen: ScreenGui)
	-- Arriba de la columna del menú (encima de Tienda y Robux).
	local pill = Instance.new("Frame")
	pill.Name = "ImpulsoServidor"
	pill.LayoutOrder = 1
	pill.Size = UDim2.fromOffset(Layout.MENU_WIDTH, 54) -- el ancho de la columna
	pill.Visible = false
	Kit.skin(pill, "boton", UIConfig.Colors.Robux)
	pill.Parent = Layout.menu()
	local title = Style.text(pill, "Texto", UIConfig.TextSizes.Body, nil, 2)
	title.Position = UDim2.fromOffset(10, 5)
	title.Size = UDim2.new(1, -20, 0, 24)
	local by = Style.text(pill, "Comprador", UIConfig.TextSizes.Small, nil, 1.5)
	by.FontFace = UIConfig.Fonts.Body
	by.Position = UDim2.fromOffset(10, 29)
	by.Size = UDim2.new(1, -20, 0, 18)

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
