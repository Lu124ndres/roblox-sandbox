--!strict
--[[
	RebirthWindow

	Renacer (botón RENACER de la columna derecha) con el estilo de la TIENDA:
	dos tarjetas con rayos, AHORA (azul) → AL RENACER (dorada, con "+N%"),
	con los peces por segundo al alimentar y el bono para siempre de monedas
	y poder (x1.25 por renacimiento, RebirthMath.bonusMultiplier); las
	barras con ícono de monedas y poder que pide (verdes al alcanzar); qué se
	reinicia (roja) y qué te quedas (verde) con íconos; y el botón grande,
	que late cuando ya alcanza (piezas en RebirthParts). El botón del HUD
	lleva un punto rojo cuando ya alcanza. Lo decide el
	servidor (remote Rebirth, Retention/Rebirth).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local RebirthMath = require(ReplicatedStorage.Shared.RebirthMath)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Icons = require(script.Parent.Parent.Interface.Icons)
local Style = require(script.Parent.Parent.Interface.Style)
local HudButtons = require(script.Parent.HudButtons)
local RebirthParts = require(script.Parent.RebirthParts)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local CARDS = Style.PALETTE.Cards
local PULSE = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local NUDGE = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local RebirthWindow = {}

local function speedText(rebirths: number): string
	return `{RebirthMath.speedText(rebirths)}/s`
end

function RebirthWindow.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local remote = remotes:WaitForChild(Protocol.Remotes.Rebirth) :: RemoteEvent
	local window = Window.create(screen, "Renacer", "Renacer", Vector2.new(760, 540))
	local hud = HudButtons.side("Renacer", "arrow", window.toggle)
	local content = window.content

	local nowValue, _, nowNote = RebirthParts.speedCard(content, "AHORA", CARDS.Blue, 0.04)
	local afterValue, gain, afterNote =
		RebirthParts.speedCard(content, "AL RENACER", CARDS.Yellow, 0.56)
	local arrow = Icons.view(content, "arrow")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Position = UDim2.new(0.5, 0, 0, 69)
	arrow.Size = UDim2.fromOffset(80, 80)
	arrow.Rotation = 90
	TweenService:Create(arrow, NUDGE, { Position = UDim2.new(0.5, 8, 0, 69) }):Play()
	local count = Style.text(content, "Veces", 24, Color3.fromRGB(255, 236, 200), 2)
	count.Position = UDim2.fromOffset(0, 146)
	count.Size = UDim2.new(1, 0, 0, 28)
	-- Lo que pide: monedas y poder, una barra con ícono para cada uno.
	local coinsNeed = RebirthParts.requirement(content, "coin", UIConfig.Colors.Coins, 0.02, 186)
	local powerNeed = RebirthParts.requirement(content, "crystal", UIConfig.Colors.Power, 0.52, 186)
	RebirthParts.listCard(content, "SE REINICIAN", CARDS.Red, 0.01, 244, {
		{ icon = "coin", label = "Monedas" },
		{ icon = "crystal", label = "Poder" },
		{ icon = "rod", label = "Mejoras" },
		{ icon = "basketFish", label = "Canasta" },
	})
	RebirthParts.listCard(content, "TE QUEDAS", CARDS.Green, 0.51, 244, {
		{ icon = "crown", label = "Títulos" },
		{ icon = "fed", label = "Kills" },
		{ icon = "pond", label = "Estanques" },
		{ icon = "fish", label = "Colección" },
		{ icon = "ticket", label = "Pases" },
	})
	local button = Style.button(content, "Renacer", Style.PALETTE.Buy, "¡RENACER!")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -4)
	button.Size = UDim2.new(0.52, 0, 0, 70)
	local buttonText = button:FindFirstChild("Texto") :: TextLabel
	local beat = Instance.new("UIScale")
	beat.Parent = button
	local pulse = TweenService:Create(beat, PULSE, { Scale = 1.06 })

	local function render()
		local rebirths = RebirthMath.count(player)
		local cost, powerCost = RebirthMath.cost(rebirths), RebirthMath.powerCost(rebirths)
		local coins, power = player:GetAttribute(ATTR.Coins), player:GetAttribute(ATTR.Power)
		local have = if type(coins) == "number" then coins else 0
		local strength = if type(power) == "number" then power else 0
		nowValue.Text = speedText(rebirths)
		afterValue.Text = speedText(rebirths + 1)
		nowNote.Text = `peces/s · {RebirthMath.bonusText(rebirths)} monedas y poder`
		afterNote.Text = `peces/s · {RebirthMath.bonusText(rebirths + 1)} monedas y poder`
		local before, after =
			RebirthMath.fishPerSecond(rebirths), RebirthMath.fishPerSecond(rebirths + 1)
		gain.Visible = after > before
		gain.Text = `+{math.round((after / math.max(before, 0.001) - 1) * 100)}%`
		count.Text = if rebirths == 0
			then "¡Tu primer renacimiento!"
			else `Renacimiento {rebirths} → {rebirths + 1}`
		coinsNeed.set(have, cost, `{NumberFormat.short(have)} / {NumberFormat.short(cost)}`)
		powerNeed.set(
			strength,
			powerCost,
			`{NumberFormat.short(strength)} / {NumberFormat.short(powerCost)}`
		)
		local ready = RebirthMath.canRebirth(have, strength, rebirths)
		buttonText.Text = if ready
			then "¡RENACER!"
			elseif have < cost then "Te faltan monedas"
			else "Te falta poder"
		local tint = if ready then Style.PALETTE.Buy else Style.PALETTE.Disabled
		button.BackgroundColor3 = tint
		local gradient = button:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient:Destroy()
		end
		Style.gradient(button, tint)
		hud.setAlert(ready)
		if ready then
			pulse:Play()
		else
			pulse:Cancel()
			beat.Scale = 1
		end
	end

	button.Activated:Connect(function()
		local coins, power = player:GetAttribute(ATTR.Coins), player:GetAttribute(ATTR.Power)
		if
			type(coins) == "number"
			and type(power) == "number"
			and RebirthMath.canRebirth(coins, power, RebirthMath.count(player))
		then
			remote:FireServer()
		end
	end)
	player:GetAttributeChangedSignal(ATTR.Coins):Connect(render)
	player:GetAttributeChangedSignal(ATTR.Rebirths):Connect(render)
	player:GetAttributeChangedSignal(ATTR.Power):Connect(render)
	window.onOpen(render)
	render()
end

return RebirthWindow
