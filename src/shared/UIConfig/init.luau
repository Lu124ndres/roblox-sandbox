--!strict
--[[
	UIConfig

	Constantes visuales de la interfaz: paleta de colores, fuentes, tamaños
	de texto, espaciados y curvas de animación (TweenInfo).

	Separado de Config.luau a propósito: Config contiene balance de juego
	(lo que afecta las reglas) y UIConfig contiene presentación (lo que
	afecta cómo se ve). Cambiar un color nunca debería requerir revisar
	la economía, y viceversa.

	Los IDs de imágenes NO van aquí; van en Assets.luau.

	Lenguaje de color del juego (también en el mapa, ver tools/generar_playa.py):
	turquesa = pescar, coral = alimentar, dorado = monedas.
]]

local FishColors = require(script.FishColors)
local Ponds = require(script.Ponds)
local RodLooks = require(script.RodLooks)
local Sounds = require(script.Sounds)

export type UIConfig = {
	-- Paleta con nombre semántico (Primary, Background, Danger), no por color (Red).
	Colors: { [string]: Color3 },

	-- Un color por estado de la barra de hambre (25 %, 50 %, 75 %, 100 %).
	HungerStageColors: { Color3 },

	-- Color y nombre de cada estanque de entrenamiento, del más débil al más fuerte.
	PondColors: { Color3 },
	PondNames: { string },

	-- Color de cada pez por id de Config.Economy.fish.
	FishColors: { [string]: Color3 },

	-- Color de cada rareza por id de Config.Economy.rarities.
	RarityColors: { [string]: Color3 },

	-- Aspecto de cada caña de la tienda (mismo orden que Config.Shop.Rod).
	RodLooks: { RodLooks.RodLook },

	-- Familias tipográficas.
	Fonts: { [string]: Font },

	-- Tamaños máximos de texto en píxeles (los textos escalan en pantallas chicas).
	TextSizes: { [string]: number },

	-- Márgenes, radios y tamaños en píxeles, para mantener un ritmo consistente.
	Spacing: { [string]: number },

	-- Curvas reutilizables para TweenService (abrir paneles, flotar, girar).
	Tweens: { [string]: TweenInfo },

	-- Efectos 3D locales: distancias en studs y tiempos en segundos.
	Effects: { [string]: number },

	-- Volumen (0..10) y tono de cada sonido de Assets.Sounds.
	Sounds: { [string]: SoundSettings },
}

export type SoundSettings = Sounds.SoundSettings
export type RodLook = RodLooks.RodLook

local UIConfig: UIConfig = {
	Colors = {
		Panel = Color3.fromRGB(18, 38, 58),
		PanelStroke = Color3.fromRGB(255, 255, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextMuted = Color3.fromRGB(184, 214, 228),
		TextStroke = Color3.fromRGB(10, 24, 38),
		Track = Color3.fromRGB(8, 22, 36),
		Coins = Color3.fromRGB(255, 206, 84),
		Power = Color3.fromRGB(150, 200, 255),
		Fishing = Color3.fromRGB(54, 196, 184),
		Feeding = Color3.fromRGB(255, 122, 100),
		Success = Color3.fromRGB(110, 226, 140),
		Warning = Color3.fromRGB(255, 186, 90),
		Robux = Color3.fromRGB(0, 176, 111),
		Bite = Color3.fromRGB(255, 92, 76),
		Bobber = Color3.fromRGB(255, 92, 76),
		BobberTop = Color3.fromRGB(255, 255, 255),
		Line = Color3.fromRGB(235, 240, 245),
		-- Enojo del gigante: calmado, molesto, furioso.
		Calm = Color3.fromRGB(110, 226, 140),
		Annoyed = Color3.fromRGB(255, 170, 60),
		Furious = Color3.fromRGB(255, 50, 40),
	},

	HungerStageColors = {
		Color3.fromRGB(110, 200, 255),
		Color3.fromRGB(84, 214, 170),
		Color3.fromRGB(255, 196, 84),
		Color3.fromRGB(255, 122, 100),
	},

	PondColors = Ponds.Colors,
	PondNames = Ponds.Names,

	FishColors = FishColors.Fish,
	RarityColors = FishColors.Rarity,
	RodLooks = RodLooks,

	Fonts = {
		Title = Font.fromEnum(Enum.Font.FredokaOne),
		Body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	},

	TextSizes = {
		Small = 18,
		Body = 22,
		Title = 28,
		Banner = 44,
		Button = 52,
	},

	Spacing = {
		Margin = 12,
		Padding = 10,
		Corner = 14,
		Stroke = 2,
		PanelTransparency = 0.18,
		HungerWidthMax = 520,
		HungerWidthMin = 260,
		HungerHeight = 100, -- incluye la fila del enojo
		BiteButtonSize = 190,
		CastButtonSize = 150,
	},

	Tweens = {
		BarFill = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Pop = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		Fade = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		Pulse = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		Bob = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		Dip = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Countdown = TweenInfo.new(1, Enum.EasingStyle.Linear),
	},

	Effects = {
		ToastSeconds = 2.2,
		BannerSeconds = 2.8,
		-- Alimentar: los peces vuelan del jugador a la boca del gigante.
		FeedThrowSeconds = 0.75,
		-- Pesca
		BobberSize = 0.9,
		CastArcHeight = 7,
		BobAmplitude = 0.12,
		NibbleDepth = 0.55, -- cuánto se hunde el corcho cuando pica
		RippleSeconds = 1.7, -- cada cuánto sale una onda del corcho
		FishJumpSeconds = 0.8,
		FishJumpHeight = 8,
		TrophySeconds = 1.6, -- raros o mejores: el jugador lo muestra en alto
		CatchCardSeconds = 2.4, -- tarjeta de la captura abajo al centro
		CoinFlySeconds = 0.7, -- monedas que vuelan al contador
		-- Gigante
		GiantGrowthSeconds = 1.2, -- constante de tiempo del crecimiento suave
		GiantBobAmplitude = 0.45,
		GiantBobSeconds = 3.4,
		GiantSwayDegrees = 3,
		GiantLookDegrees = 28, -- cuánto gira mirando alrededor
		GiantLookSeconds = 10,
		GiantBreath = 0.018, -- pulso de escala al respirar
		GiantTurnSeconds = 0.45, -- giro hacia quien lo alimenta
		GiantAttentionSeconds = 2.4,
		GiantBounceHeight = 2.4,
		GiantStageJumpHeight = 9,
		SpoutMinSeconds = 9,
		SpoutMaxSeconds = 16,
		-- Ambiente
		DayCycleMinutes = 16, -- un día completo; 3/4 es de día
		LighthouseTurnSeconds = 9,
		FoamPulseSeconds = 2.6,
		BuoyBobAmplitude = 0.45,
		SeagullCount = 4,
		BatCount = 9,
		SeagullRadius = 95,
		SeagullHeight = 42,
		JumpingFishMinSeconds = 4,
		JumpingFishMaxSeconds = 10,
		SeagullCallMinSeconds = 9,
		SeagullCallMaxSeconds = 20,
	},

	Sounds = Sounds,
}

return table.freeze(UIConfig)
