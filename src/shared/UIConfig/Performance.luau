--!strict
--[[
	Performance

	Números de rendimiento de los efectos locales: distancias de detalle
	(en studs), ritmos de actualización (en segundos) y topes. Pensados para
	servidores de 40-50 jugadores con muchos teléfonos modestos. Sección de
	UIConfig en su propio archivo (se pide como UIConfig.Performance) para
	que init.luau no pase de 200 líneas.
]]

local Performance: { [string]: number } = {
	-- Nivel de detalle de los otros jugadores (Effects/Distance).
	TierNear = 60, -- más cerca: todo el detalle
	TierMid = 150, -- más lejos: casi nada
	TierHysteresis = 8, -- margen para no cambiar de nivel en el borde
	TierUpdateSeconds = 0.25,
	LowFxDistanceScale = 0.5, -- con efectos reducidos los cortes se acercan

	-- Sonidos (Audio/Sounds).
	SoundDefaultReach = 150, -- sonidos 3D sin rollOff: más lejos no suenan
	SoundMaxPerKey = 4, -- copias a la vez del mismo sonido
	SoundMaxLifetime = 12, -- por si un sonido nunca termina

	-- Pesca de los otros jugadores.
	RodMidUpdateSeconds = 0.1, -- caña a 10 Hz en el nivel medio
	CatchSplashOnlyDistance = 100, -- más lejos la captura es solo el chapuzón
	CatchHideDistance = 150, -- más lejos no se dibuja nada
	CatchStashSeconds = 0.15, -- vuelo del pez a la canasta

	-- Vigilante de cuadros por segundo (Settings/FpsWatchdog).
	FpsWatchdogMin = 35, -- por debajo de este promedio...
	FpsWatchdogSeconds = 10, -- ...durante este tiempo se activan efectos reducidos
	FpsWatchdogGraceSeconds = 15, -- no mide mientras el juego termina de cargar

	-- Cielo (Ambient/SkyCycle).
	SkyUpdateSeconds = 0.5,
	SkyClockStep = 0.02, -- horas de ClockTime que fuerzan una actualización
	SkyZoneStep = 0.02, -- cambio de la mezcla del cráter que fuerza una actualización

	-- Mar (Ambient/SeaLife).
	FoamAnimateDistance = 150,
	FoamSlices = 4, -- cada paso mueve una de estas partes de la espuma
	GlintAreaStuds = 160, -- lado del área de destellos alrededor de la cámara
	GlintRate = 14,

	-- Gigante (Giant/GiantBody).
	GiantScaleStep = 0.005, -- solo se reescala si cambia más de 0.5 %
	GiantBreathLift = 0.5, -- la respiración sube y baja esta fracción de GiantBreath * alto
	GiantOutlineSeconds = 1 / 15, -- el contorno late a 15 Hz

	-- Carteles sobre la cabeza (Interface/Overhead).
	OverheadDistance = 120,
	OverheadLowFxDistance = 60,

	-- Estanques (Training/PondFx).
	PondAnimateDistance = 220,
}

return table.freeze(Performance)
