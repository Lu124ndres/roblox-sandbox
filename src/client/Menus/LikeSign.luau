--!strict
--[[
	LikeSign

	Letrero de la meta de likes en la plaza (pedido del usuario el 2026-10-26:
	que todos lo vean sin estorbar el juego). Muestra la barra «👍 37 / 50» y,
	al llegar, el código para canjear. Lo que muestra lo decide el servidor
	(server/Social/LikeGoal, carpeta MetaLikes); sin meta activa no se ve.
	Si no se pudieron leer los likes, muestra solo la meta.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)
local PlazaSign = require(script.Parent.PlazaSign)

local ATTR = Protocol.LikeGoalAttributes
-- { x, z } a un lado del camino del spawn, de frente a quien llega, fuera del paso.
local SPOT = Vector2.new(22, -22)
local BOARD = Vector3.new(16, 9, 0.8) -- ancho, alto y grosor del tablero (studs)
local LIFT = 2.5
local PIXELS_PER_STUD = 50
local GREEN = Color3.fromRGB(110, 235, 90)
local TRACK = Color3.fromRGB(30, 22, 18)
local FILL = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local LikeSign = {}

local function bar(parent: Instance): Frame
	local track = Instance.new("Frame")
	track.Name = "Barra"
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.fromScale(0.5, 0.56)
	track.Size = UDim2.fromScale(0.84, 0.13)
	track.BackgroundColor3 = TRACK
	track.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = track
	local stroke = Instance.new("UIStroke")
	stroke.Color = Kit.GOLD_OUTLINE
	stroke.Thickness = 5
	stroke.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Relleno"
	fill.BackgroundColor3 = GREEN
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = track
	corner:Clone().Parent = fill
	return fill
end

function LikeSign.start()
	local player = Players.LocalPlayer
	local folder = ReplicatedStorage:WaitForChild(Protocol.LikeGoalFolder)
	local function goal(): number
		local value = folder:GetAttribute(ATTR.Goal)
		return if type(value) == "number" then value else 0
	end
	while goal() <= 0 do
		folder:GetAttributeChangedSignal(ATTR.Goal):Wait()
	end
	local board = PlazaSign.build("LetreroLikes", SPOT, BOARD, LIFT)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "LetreroLikes"
	gui.Adornee = board
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundTransparency = 1
	panel.Size = UDim2.fromScale(1, 1)
	panel.Parent = gui
	Kit.skin(panel, "panel")

	local title = Style.text(panel, "Titulo", 100, nil, 6)
	title.Position = UDim2.fromScale(0.05, 0.07)
	title.Size = UDim2.fromScale(0.9, 0.2)
	Kit.gold(title)
	local count = Style.text(panel, "Cuenta", 120, Color3.new(1, 1, 1), 7)
	count.Position = UDim2.fromScale(0.05, 0.28)
	count.Size = UDim2.fromScale(0.9, 0.25)
	local fill = bar(panel)
	local footer = Style.text(panel, "Pie", 70, GREEN, 5)
	footer.Position = UDim2.fromScale(0.05, 0.76)
	footer.Size = UDim2.fromScale(0.9, 0.15)

	local function refresh()
		local likes = folder:GetAttribute(ATTR.Likes)
		local code = folder:GetAttribute(ATTR.Code)
		local target = goal()
		board.Parent.Parent = if target > 0 then Workspace else nil
		gui.Enabled = target > 0
		local known = type(likes) == "number" and likes >= 0
		if type(code) == "string" and code ~= "" then
			title.Text = "¡META CUMPLIDA!"
			count.Text = code
			fill.Parent.Visible = false
			footer.Text = "Canjéalo en Códigos"
		else
			title.Text = "META DE LIKES"
			count.Text = if known then `👍 {likes} / {target}` else `👍 ? / {target}`
			fill.Parent.Visible = known
			if known then
				local ratio = math.clamp((likes :: number) / math.max(target, 1), 0, 1)
				TweenService:Create(fill, FILL, { Size = UDim2.fromScale(ratio, 1) }):Play()
			end
			footer.Text = "¡Dale like y se libera un código!"
		end
	end
	for _, name in { ATTR.Likes, ATTR.Goal, ATTR.Code } do
		folder:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

return LikeSign
