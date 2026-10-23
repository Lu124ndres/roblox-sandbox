--!strict
--[[
	TimedBadges

	Insignias de BoostBadges para los impulsos personales con tiempo, al lado
	de las demás. Solo se ven mientras duran, con el multiplicador sobre el
	ícono y el tiempo que queda debajo:
		Poder    x2 de poder (códigos, misiones, regalos, ruleta, invitaciones,
		         pack de inicio)
		Monedas  x2 de monedas de la ruleta
	Reclamar otro con uno activo suma tiempo, no multiplica: por eso el reloj.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Perks = require(ReplicatedStorage.Shared.Perks)
local RetentionBonus = require(ReplicatedStorage.Shared.RetentionBonus)
local SPIN = require(ReplicatedStorage.Shared.Config.Spin)
local Icons = require(script.Parent.Icons)
local Style = require(script.Parent.Style)

local REFRESH_SECONDS = 0.5
local ON_COLOR = Color3.fromRGB(140, 255, 120)

type Badge = { button: TextButton, icon: GuiObject, value: TextLabel }
type MakeBadge = (name: string, order: number, icon: GuiObject) -> Badge

local TimedBadges = {}

-- 75 s → "1:15"; 3725 s → "1:02:05".
local function clock(seconds: number): string
	local total = math.ceil(seconds)
	if total >= 3600 then
		return string.format("%d:%02d:%02d", total // 3600, total // 60 % 60, total % 60)
	end
	return string.format("%d:%02d", total // 60, total % 60)
end

local function timed(
	make: MakeBadge,
	row: Frame,
	name: string,
	order: number,
	icon: string,
	multiplier: number,
	secondsLeft: () -> number
): () -> ()
	local entry = make(name, order, Icons.view(row, icon))
	entry.value.TextColor3 = ON_COLOR
	local tag = Style.text(entry.button, "Multiplicador", 18, ON_COLOR, 2.5)
	tag.Text = `x{multiplier}`
	tag.AnchorPoint = Vector2.new(1, 0)
	tag.Position = UDim2.new(1, 4, 0, -4)
	tag.Size = UDim2.fromOffset(32, 18)
	tag.ZIndex = 2
	entry.button.Visible = false
	return function()
		local left = secondsLeft()
		entry.button.Visible = left > 0
		if left > 0 then
			entry.value.Text = clock(left)
		end
	end
end

-- `make` crea una insignia en la fila (la misma de BoostBadges); van después de `firstOrder`.
function TimedBadges.mount(row: Frame, firstOrder: number, make: MakeBadge)
	local player = Players.LocalPlayer
	local refreshers = {
		timed(
			make,
			row,
			"ImpulsoPoder",
			firstOrder,
			"crystal",
			Config.Social.personalBoostMultiplier,
			function()
				return Perks.personalBoostSeconds(player)
			end
		),
		timed(
			make,
			row,
			"ImpulsoMonedas",
			firstOrder + 1,
			"coin",
			SPIN.coinBoostMultiplier,
			function()
				return RetentionBonus.coinBoostSeconds(player)
			end
		),
	}
	task.spawn(function()
		while true do
			for _, refresh in refreshers do
				refresh()
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return TimedBadges
