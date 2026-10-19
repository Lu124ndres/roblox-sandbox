--!strict
--[[
	CodesWindow

	Ventana para canjear códigos (botón con el boleto en la barra de Roblox):
	una caja de texto y "Canjear". El servidor decide (remote RedeemCode) y
	responde con Notice "code"; aquí se muestra el resultado.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local Window = require(script.Parent.Window)

local COLORS = UIConfig.Colors
local MESSAGES: { [string]: { text: string, color: Color3 } } = {
	invalid = { text = "Ese código no existe", color = COLORS.Bite },
	used = { text = "Ya usaste ese código", color = COLORS.Warning },
	expired = { text = "Ese código ya venció", color = COLORS.Warning },
}

local CodesWindow = {}

function CodesWindow.start(screen: ScreenGui)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local redeem = remotes:WaitForChild(Protocol.Remotes.RedeemCode) :: RemoteEvent
	local notice = remotes:WaitForChild(Protocol.Remotes.Notice) :: RemoteEvent
	local window = Window.create(screen, "Codigos", "Códigos", Vector2.new(460, 250))
	HudButtons.top("Códigos", "ticket", window.toggle)

	-- La caja va en un hueco tallado (la piedra va en un marco aparte: si fuera
	-- hija de la caja, taparía el texto).
	local slot = Instance.new("Frame")
	slot.Name = "Hueco"
	slot.Size = UDim2.fromScale(1, 0.32)
	slot.Parent = window.content
	Kit.skin(slot, "hondo")
	local box = Instance.new("TextBox")
	box.Name = "Codigo"
	box.PlaceholderText = "Escribe un código"
	box.Text = ""
	box.ClearTextOnFocus = false
	box.FontFace = UIConfig.Fonts.Title
	box.TextScaled = true
	box.TextColor3 = COLORS.Text
	box.PlaceholderColor3 = COLORS.TextMuted
	box.BackgroundTransparency = 1
	box.Position = UDim2.fromOffset(16, 10)
	box.Size = UDim2.new(1, -32, 1, -20)
	box.ZIndex = 2
	box.Parent = slot

	local status = Style.text(window.content, "Estado", 22, COLORS.TextMuted, 2)
	status.Position = UDim2.fromScale(0, 0.36)
	status.Size = UDim2.fromScale(1, 0.2)
	status.Text = "Búscalos en el grupo y las redes del juego"

	local button = Style.button(window.content, "Canjear", Style.PALETTE.Buy, "Canjear")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 1)
	button.Size = UDim2.fromScale(0.5, 0.3)

	local function send()
		local text = box.Text
		if #text > 0 and #text <= 30 then
			redeem:FireServer(text)
			status.Text = "Revisando..."
			status.TextColor3 = COLORS.TextMuted
		end
	end
	button.Activated:Connect(send)
	box.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			send()
		end
	end)
	notice.OnClientEvent:Connect(function(kind: unknown, result: unknown, reward: unknown)
		if kind ~= "code" then
			return
		end
		if result == "ok" then
			status.Text = `¡Listo! {if type(reward) == "string" then reward else ""}`
			status.TextColor3 = COLORS.Success
			box.Text = ""
		elseif type(result) == "string" and MESSAGES[result] then
			status.Text = MESSAGES[result].text
			status.TextColor3 = MESSAGES[result].color
		end
	end)
end

return CodesWindow
