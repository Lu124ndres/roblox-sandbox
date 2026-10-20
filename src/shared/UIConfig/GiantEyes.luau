--!strict
--[[
	GiantEyes

	Las pupilas que siguen al jugador local (client/Giant/GiantEyes). Sección de
	UIConfig en su propio archivo (se pide como UIConfig.GiantEyes). Dónde está
	cada ojo lo dice GiantEyesData (medido en Blender); aquí va cómo se ve la
	pupila de cada base y cómo se mueve.

	Las medidas de las partes son fracciones del lado menor del ojo, así crecen
	con el gigante (ScaleTo) sin tocar nada. Los ángulos van en radianes, los
	tiempos en segundos y las distancias en "lados de ojo": distancia a la cámara
	dividida por el lado menor del ojo (un ojo grande se sigue viendo de más lejos).
]]

export type Look = {
	color: Color3, -- color de la pupila
	stageColors: { [number]: Color3 }?, -- color por etapa, si alguna cambia (1..4)
	material: Enum.Material, -- de la pupila: Neon brilla, SmoothPlastic no
	coverMaterial: Enum.Material, -- de la tapa (su color lo da GiantEyesData.cover)
	size: number, -- lado de la pupila, fracción del lado menor del ojo
	travel: number, -- cuánto se corre del centro, fracción del medio ojo (0..1)
	thickness: number, -- grosor de la pupila, fracción del lado menor del ojo
}

export type GiantEyesConfig = {
	Looks: { [string]: Look }, -- por base del gigante (Config.GiantDef.modelBase)

	-- Capas: cuánto sobresalen de la cara del ojo (fracción del lado menor del ojo).
	CoverThickness: number, -- grosor de la tapa
	Gap: number, -- separación entre la cara del ojo, la tapa y la pupila (sin planos iguales)

	-- Seguimiento.
	MaxAngle: number, -- rad entre el frente del ojo y el jugador para llegar al tope
	ConeFull: number, -- rad: hasta aquí lo sigue de lleno
	ConeZero: number, -- rad: desde aquí (detrás del ojo) vuelve al centro
	DeadAngle: number, -- rad: corre la vista solo si el jugador se fue más que esto
	SettleAngle: number, -- rad: o el ajuste fino...
	SettleSeconds: number, -- ...si pasó este tiempo desde que fijó la vista
	SpringHz: number, -- resorte de la pupila (oscilaciones por segundo)
	SpringDamping: number, -- 1 = llega sin pasarse; menos rebota un poco

	-- Detalles de vida (fracción del recorrido).
	MicroAmount: number, -- saltitos de la vista (microsacadas)
	MicroSeconds: number, -- cada cuánto salta
	DriftAmount: number, -- deriva lenta
	DriftHz: number, -- qué tan lenta (ciclos por segundo)

	-- Rendimiento (en lados de ojo; con efectos reducidos los cortes se acercan).
	MidRatio: number, -- más lejos: el seguimiento se recalcula a MidSeconds
	MidSeconds: number,
	StopRatio: number, -- más lejos: se esconden y no se actualizan
	StopHysteresis: number, -- margen (fracción) para no prender y apagar en el borde
	MoveEpsilon: number, -- studs: si la pupila se movió menos, no se reescribe el CFrame
}

local rgb = Color3.fromRGB
local M = Enum.Material

local GiantEyes: GiantEyesConfig = {
	Looks = {
		Minotauro = {
			color = rgb(20, 12, 8), -- #140C08 sobre el ojo ámbar
			material = M.SmoothPlastic,
			coverMaterial = M.Neon,
			size = 0.42,
			travel = 0.5,
			thickness = 0.05,
		},
		DragonMarino = {
			color = rgb(16, 18, 20), -- oscura sobre su ojo brillante
			material = M.SmoothPlastic,
			coverMaterial = M.Neon,
			size = 0.4,
			travel = 0.5,
			thickness = 0.05,
		},
		ZorroDeAgua = {
			color = rgb(18, 58, 110), -- #123A6E azul marino sobre el ojo claro
			material = M.SmoothPlastic,
			coverMaterial = M.Neon,
			size = 0.45,
			travel = 0.45,
			thickness = 0.05,
		},
		Orca = {
			color = rgb(255, 43, 43), -- #FF2B2B en la cuenca oscura
			stageColors = { [4] = rgb(255, 30, 30) }, -- #FF1E1E la forma final
			material = M.Neon,
			coverMaterial = M.SmoothPlastic, -- sin tapa
			size = 0.38,
			travel = 0.5,
			thickness = 0.06,
		},
	},

	CoverThickness = 0.03,
	Gap = 0.01,

	MaxAngle = 0.9,
	ConeFull = 1.25,
	ConeZero = 1.7,
	DeadAngle = 0.08,
	SettleAngle = 0.02,
	SettleSeconds = 1.5,
	SpringHz = 3.5,
	SpringDamping = 0.75,

	MicroAmount = 0.07,
	MicroSeconds = 0.85,
	DriftAmount = 0.05,
	DriftHz = 0.2,

	MidRatio = 60,
	MidSeconds = 1 / 15,
	StopRatio = 250,
	StopHysteresis = 0.1,
	MoveEpsilon = 0.002,
}

for _, look in GiantEyes.Looks do
	table.freeze(look)
end
table.freeze(GiantEyes.Looks)

return table.freeze(GiantEyes)
