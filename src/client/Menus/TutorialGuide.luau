--!strict
--[[
	TutorialGuide

	El tutorial del primer minuto, como el de referencias/Ejemplo.mp4: una
	acción a la vez, sin leer de más, y la recompensa a la vista enseguida.
	El jugador aparece en la playa (TutorialSpawn) y:
		1. pesca 3 peces           2. le da de comer al gigante
		3. entrena en el estanque  4. compra una mejora desde MEJORAS
	En cada paso:
		- un anuncio grande una sola vez («¡PESCA!», TutorialCallout);
		- la línea de objetivo chica con el avance y cómo se hace
		  (TutorialBanner), con «+1» al sumar y «¡LISTO! +25» al cumplirlo;
		- en el mundo, flechas en el suelo por los puntos de paso (GuidePath,
		  tramos de TutorialLegs) y un aro de neón en el destino (GuideRing);
		- en el paso de comprar, el velo con hueco y la mano sobre MEJORAS y,
		  con la ventana abierta, sobre comprar (TutorialSpotlight).
	El avance lo decide el servidor (atributos Tutorial y TutorialCount);
	nada queda puesto en el mapa.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Protocol = require(ReplicatedStorage.Shared.Protocol)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local ShopController = require(script.Parent.Parent.Shop.ShopController)
local GuidePath = require(script.Parent.GuidePath)
local GuideRing = require(script.Parent.GuideRing)
local TutorialBanner = require(script.Parent.TutorialBanner)
local TutorialCallout = require(script.Parent.TutorialCallout)
local TutorialHud = require(script.Parent.TutorialHud)
local TutorialLegs = require(script.Parent.TutorialLegs)
local TutorialSpotlight = require(script.Parent.TutorialSpotlight)
local Window = require(script.Parent.Window)

local ATTR = Protocol.PlayerAttributes
local STEPS = Config.Retention.tutorial
local ARRIVE = 10 -- studs del destino a los que las flechas se van
local DONE_SECONDS = 1.4 -- lo que se ve «¡LISTO!» antes del paso siguiente

local TutorialGuide = {}

function TutorialGuide.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	local banner = TutorialBanner.new(screen)
	local callout = TutorialCallout.new(screen)
	local spotlight = TutorialSpotlight.new(screen)
	local hud = TutorialHud.new(screen)
	local route = GuidePath.new()
	local ring = GuideRing.new()
	local shownStep = -1 -- el paso que muestra la línea (-1: ninguno)
	local lastCount = 0
	local shownHint = ""
	local celebrating = false

	local function step(): number
		local value = player:GetAttribute(ATTR.Tutorial)
		return (if type(value) == "number" then value else 0) + 1
	end

	local function count(): number
		local value = player:GetAttribute(ATTR.TutorialCount)
		return if type(value) == "number" then value else 0
	end

	local function position(): Vector3?
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root.Position else nil
	end

	-- Pone en la línea el paso actual (con el avance y cómo se hace).
	local function paint(index: number)
		local current = STEPS[index]
		local leg = TutorialLegs.forStep(current.id, position() or Vector3.zero)
		shownHint = leg.hint
		local progress = if current.goal > 1 then `{count()}/{current.goal}` else ""
		banner.set(current.text, progress, leg.hint)
	end

	-- Empieza el paso `index`: anuncio grande una vez y la línea.
	local function begin(index: number)
		shownStep = index
		lastCount = count()
		callout.play(STEPS[index].intro)
		paint(index)
		banner.show(true)
	end

	local function refresh()
		local index = step()
		local loaded = player:GetAttribute(ATTR.DataLoaded) == true
		-- Solo el tutorial a la vista (hasta saber si lo tiene, detrás de la pantalla de
		-- carga); en el de comprar, solo MEJORAS.
		local current = STEPS[index]
		hud.set(
			not loaded or current ~= nil,
			if loaded
					and current
					and current.id == "comprar"
				then ShopController.hudButton()
				else nil
		)
		if not loaded or not STEPS[index] then
			if shownStep ~= -1 and loaded then -- terminó el último: «¡LISTO!» y se va
				banner.done(STEPS[shownStep].coins + Config.Retention.tutorialBonus)
				task.delay(DONE_SECONDS, function()
					banner.show(false)
				end)
			else
				banner.show(false)
			end
			shownStep = -1
			return
		end
		if celebrating then
			return
		end
		if shownStep == -1 or index < shownStep then -- empieza (o el admin lo reinició)
			begin(index)
		elseif shownStep ~= index then -- cumplió un paso: «¡LISTO! +N» y el siguiente
			celebrating = true
			banner.done(STEPS[shownStep].coins)
			shownStep = index
			task.delay(DONE_SECONDS, function()
				celebrating = false
				if STEPS[step()] then
					begin(step())
				end
			end)
		else
			local now = count()
			if now > lastCount then
				banner.bump(now - lastCount)
			end
			lastCount = now
			paint(index)
		end
	end
	for _, attribute in { ATTR.Tutorial, ATTR.TutorialCount, ATTR.DataLoaded } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	InputHints.onChange(refresh)
	refresh()

	-- Al abrir MEJORAS en el paso de comprar, directo a la mejora más barata.
	Window.onAnyChange(function(window: Window.Window, opened: boolean)
		local current = STEPS[step()]
		if opened and current and current.id == "comprar" and window.frame.Name == "Mejoras" then
			ShopController.showCheapest(player)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local current = STEPS[step()]
		local at = position()
		if not current or shownStep == -1 or celebrating or not at then
			route.hide()
			ring.show(false)
			spotlight.focus(nil)
			return
		end
		if current.id == "comprar" then
			route.hide()
			ring.show(false)
			spotlight.focus(ShopController.tutorialTarget())
			if TutorialLegs.forStep(current.id, at).hint ~= shownHint then -- abrió o cerró MEJORAS
				paint(shownStep)
			end
			return
		end
		spotlight.focus(nil)
		local leg = TutorialLegs.forStep(current.id, at)
		if leg.hint ~= shownHint then -- llegó al volcán: cambia cómo se hace
			paint(shownStep)
		end
		local target = leg.points[#leg.points]
		if not target then
			route.hide()
			ring.show(false)
			return
		end
		ring.place(target)
		ring.show(true)
		local flat = Vector3.new(target.X - at.X, 0, target.Z - at.Z)
		if flat.Magnitude < ARRIVE then
			route.hide()
			return
		end
		route.update(at, leg.points, os.clock())
	end)
end

return TutorialGuide
