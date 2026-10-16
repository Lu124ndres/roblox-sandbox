--!strict
--[[
	FeedPop

	Lo que hace satisfactorio dar de comer:
		trail  cada pez vuela dejando una estela brillante del color de su
		       rareza (y crece un poco al despegar);
		chomp  al llegar a la boca: onda de choque que se abre, chispas y
		       destellos del color del pez, y para los peces del jugador local
		       un "¡ÑAM!" con el combo (x2, x3...) que salta y sube, la mordida
		       cada vez más aguda y un golpecito de cámara en los combos altos.
	El combo cuenta los peces propios que llegan seguidos (menos de
	COMBO_SECONDS entre uno y otro). Todo local y se limpia solo.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FishCatalog = require(ReplicatedStorage.Shared.FishCatalog)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Parent.Audio.Sounds)
local CameraShake = require(script.Parent.Parent.Effects.CameraShake)
local Fx = require(script.Parent.Parent.Effects.Fx)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local COMBO_SECONDS = 1.3
local WORDS = { "¡ÑAM!", "¡ÑAM!", "¡RICO!", "¡ÑAM ÑAM!", "¡DELICIOSO!", "¡FESTÍN!" }

local FeedPop = {}

local combo, lastLocal = 0, 0
local folder = Instance.new("Folder")
folder.Name = "ComidaEfectos"
folder.Parent = Workspace

function FeedPop.color(fishId: string): Color3
	local rarity = FishCatalog.rarity(fishId)
	return UIConfig.RarityColors[rarity.id] or Color3.new(1, 1, 1)
end

-- Estela brillante detrás del pez y un saltito de tamaño al despegar.
function FeedPop.trail(model: Model, color: Color3)
	local body = model.PrimaryPart
	if not body or ClientSettings.fxScale() <= 0 then
		return
	end
	local size = body.Size
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position = Vector3.new(0, size.Y * 0.35, size.Z * 0.3)
	a1.Position = Vector3.new(0, -size.Y * 0.35, size.Z * 0.3)
	a0.Parent, a1.Parent = body, body
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	trail.Transparency = NumberSequence.new(0.1, 1)
	trail.Lifetime = 0.35
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = body
end

-- Onda de choque: una esfera de neón que se abre y se apaga.
local function shockwave(position: Vector3, radius: number, color: Color3)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Transparency = 0.25
	ball.Anchored, ball.CanCollide, ball.CanQuery, ball.CanTouch = true, false, false, false
	ball.CastShadow = false
	ball.Size = Vector3.one * radius * 0.3
	ball.Position = position
	ball.Parent = folder
	TweenService:Create(
		ball,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * radius * 2.2, Transparency = 1 }
	):Play()
	Debris:AddItem(ball, 0.4)
end

-- "¡ÑAM! x5" que salta, sube y se desvanece. Hay uno solo a la vez: con el
-- combo seguido el mismo cartel cambia de texto y vuelve a saltar.
type Word = {
	anchor: Attachment,
	gui: BillboardGui,
	label: TextLabel,
	stroke: UIStroke,
	pop: UIScale,
}
local live: Word? = nil
local wordToken = 0

local function newWord(): Word
	local anchor = Instance.new("Attachment")
	anchor.Parent = Workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	gui.Adornee = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(30, 20, 40)
	stroke.Parent = label
	local pop = Instance.new("UIScale")
	pop.Parent = label
	label.Parent = gui
	gui.Parent = anchor
	return { anchor = anchor, gui = gui, label = label, stroke = stroke, pop = pop }
end

local function word(position: Vector3, text: string, color: Color3, big: number)
	local w = live or newWord()
	live = w
	wordToken += 1
	local token = wordToken
	w.anchor.WorldPosition = position
	w.gui.Size = UDim2.fromScale(6 * big, 2 * big)
	w.label.Text = text
	w.label.TextColor3 = color
	w.label.TextTransparency, w.stroke.Transparency = 0, 0
	w.pop.Scale = if w.gui.StudsOffset.Y > 0 then 0.75 else 0.2
	w.gui.StudsOffset = Vector3.zero
	local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.45)
	TweenService:Create(w.pop, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(
		w.gui,
		TweenInfo.new(0.9, Enum.EasingStyle.Quad),
		{ StudsOffset = Vector3.new(0, 4 * big, 0) }
	):Play()
	TweenService:Create(w.label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(w.stroke, fade, { Transparency = 1 }):Play()
	task.delay(1, function()
		if wordToken == token and live == w then
			live = nil
			w.anchor:Destroy()
		end
	end)
end

-- Llega un pez a la boca. size: alto del gigante (para el tamaño de la onda).
function FeedPop.chomp(position: Vector3, color: Color3, size: number, isLocal: boolean)
	local radius = math.clamp(size * 0.12, 2, 14)
	if ClientSettings.fxScale() > 0 then
		shockwave(position, radius, color)
	end
	Fx.sparkle(position, color, 10)
	Fx.sparkle(position, UIConfig.Colors.Coins, 6)
	if not isLocal then
		return
	end
	local now = os.clock()
	combo = if now - lastLocal <= COMBO_SECONDS then combo + 1 else 1
	lastLocal = now
	local step = math.min(combo, 12)
	Sounds.play("Chomp", position, 0.9 + step * 0.05)
	Sounds.play("CoinPop", position, 1 + step * 0.06)
	local text = WORDS[math.min(1 + combo // 4, #WORDS)]
	if combo >= 2 then
		text ..= ` x{combo}`
	end
	word(
		position,
		text,
		if combo >= 8 then UIConfig.Colors.Coins else Color3.new(1, 1, 1),
		1 + math.min(combo, 20) * 0.03
	)
	if combo % 5 == 0 then
		CameraShake.shake(0.12 + math.min(combo, 30) * 0.006, 0.25)
		Fx.sparkle(position, UIConfig.Colors.Coins, 24)
	end
end

return table.freeze(FeedPop)
