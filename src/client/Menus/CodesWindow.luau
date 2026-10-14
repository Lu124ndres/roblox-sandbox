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
local Style = require(script.Parent.Parent.Interface.Style)
local Ui = require(script.Parent.Parent.Ui)
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

	local box = Instance.new("TextBox")
	box.Name = "Codigo"
	box.PlaceholderText = "Escribe un código"
	box.Text = ""
	box.ClearTextOnFocus = false
	box.FontFace = UIConfig.Fonts.Title
	box.TextScaled = true
	box.TextColor3 = COLORS.Text
	box.PlaceholderColor3 = COLORS.TextMuted
	box.BackgroundColor3 = COLORS.Track
	box.Size = UDim2.new(1, 0, 0.32, 0)
	Ui.corner(box, 12)
	Style.border(box, 3)
	box.Parent = window.content
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	padding.Parent = box

	local status = Style.text(window.content, "Estado", 22, COLORS.TextMuted, 1.5)
	status.Position = UDim2.fromScale(0, 0.36)
	status.Size = UDim2.new(1, 0, 0.2, 0)
	status.Text = "Búscalos en el grupo y las redes del juego"

	local button = Style.button(window.content, "Canjear", COLORS.Robux, "Canjear")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 1)
	button.Size = UDim2.new(0.5, 0, 0.3, 0)

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
