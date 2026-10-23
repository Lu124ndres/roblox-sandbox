--!strict
--[[
	FeedFeedback

	Lo que se ve al alimentar al gigante: monedas que vuelan al contador (sin
	aviso de texto) y avisos de carga vacía, evolución, descanso o gigante
	satisfecho. Las monedas salen de la boca, una por cada pez propio que
	llega (el contador ya sube lote a lote en el servidor); la ráfaga del
	final solo sale si no se vio ningún pez. Los números vienen del servidor;
	aquí solo se muestran.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Sounds = require(script.Parent.Audio.Sounds)
local CoinBurst = require(script.Parent.Effects.CoinBurst)
local FeedThrow = require(script.Parent.Giant.FeedThrow)
local GiantName = require(script.Parent.GiantName)
local Toasts = require(script.Parent.Toasts)

local COLORS = UIConfig.Colors

local FeedFeedback = {}

function FeedFeedback.start(toasts: Toasts.Toasts, screen: ScreenGui, coinLabel: GuiObject)
	local remotes = ReplicatedStorage:WaitForChild(Protocol.RemotesFolder)
	local feedResult = remotes:WaitForChild(Protocol.Remotes.FeedResult) :: RemoteEvent
	local dripped = false -- en esta entrega ya salió alguna moneda por pez

	-- Cada pez propio que muerde suelta una moneda (pedido del usuario el
	-- 2026-10-23: antes salían todas juntas al soltar). Si la boca queda fuera de
	-- cuadro, sale del centro de la pantalla.
	FeedThrow.onLocalArrive(function(position: Vector3)
		local camera = Workspace.CurrentCamera
		local origin = screen.AbsoluteSize * Vector2.new(0.5, 0.62)
		if camera then
			local point, visible = camera:WorldToScreenPoint(position)
			if visible then
				origin = Vector2.new(point.X, point.Y)
			end
		end
		dripped = true
		CoinBurst.drip(screen, coinLabel, origin)
	end)

	feedResult.OnClientEvent:Connect(function(status: unknown, fishCount: unknown, coins: unknown)
		if status == "ok" and type(fishCount) == "number" and type(coins) == "number" then
			-- Solo las monedas que vuelan al contador: el aviso con el total tapaba la
			-- vista en cada mordida (pedido del usuario el 2026-10-21).
			if not dripped then
				Sounds.play("Coins")
				CoinBurst.burst(screen, coinLabel, coins, function() end)
			end
			dripped = false
		elseif status == "empty" then
			toasts.show("No llevas peces: pesca en la orilla de la isla", COLORS.Fishing)
		elseif status == "evolving" then
			toasts.show(
				`¡{GiantName.current(true)} está evolucionando! Espera unos segundos`,
				COLORS.Power
			)
		elseif status == "resting" then
			toasts.show("Está descansando: quédate en el volcán y entrena", COLORS.Power)
		elseif status == "full" then
			toasts.show(`{GiantName.current(true)} ya no tiene hambre`, COLORS.Success)
		end
	end)
end

return FeedFeedback
