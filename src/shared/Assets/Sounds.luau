--!strict
--[[
	Assets/Sounds

	Efectos y ambiente (Assets.Sounds). Los "rbxasset://sounds/..." vienen instalados con
	Roblox (no hay que subirlos). Las claves en MISSING no suenan. Volumen, tono y alcance de
	cada uno: UIConfig/Sounds (y client/Audio/MinoVoces para las voces del minotauro).
]]

local Sounds: { [string]: string } = {
	-- Ambiente
	OceanWaves = "rbxassetid://137826155053556", -- "Ocean waves" (3:03)
	Seagull = "rbxassetid://111686121161530", -- graznido corto (0:05)
	-- Pesca
	RodOut = "rbxasset://sounds/action_jump.mp3",
	Cast = "rbxassetid://135315310485417", -- latigazo (sword swing)
	Plop = "rbxasset://sounds/impact_water.mp3",
	Bite = "rbxassetid://137273815815490", -- burbuja (bubble pop)
	Reel = "rbxassetid://79404754846319", -- carrete (fishing reel)
	Catch = "rbxasset://sounds/impact_water.mp3",
	Escape = "rbxasset://sounds/impact_water.mp3",
	FishFlop = "rbxassetid://9114447775", -- "Fish Flop Gooshy 5"
	CatchPop = "rbxassetid://109359226723492", -- "cartoon bubble pop" (común y poco común)
	RareCatch = "rbxassetid://108936817882815", -- "item drop 3 rare"
	EpicCatch = "rbxassetid://112485797063762", -- "UI - Level Up"
	LegendaryCatch = "rbxassetid://134821092416328", -- "Rewards Level Up Next Tier"
	Whoosh = "rbxassetid://123796710194563", -- "Whoosh" (peces lanzados al gigante)
	-- Gigante
	Chomp = "rbxassetid://99444504938110", -- mordida (eating sound)
	OrcaCall = "rbxassetid://5696958591", -- "Orca sounds"
	Spout = "rbxasset://sounds/action_swim.mp3",
	BigSplash = "rbxasset://sounds/impact_water.mp3",
	StageUp = "rbxassetid://3454671965", -- fanfarria (badge fanfare)
	Roar = "rbxassetid://133651202885353", -- "Monster Roar"
	-- Minotauro (biblioteca con licencia de Roblox: ProSoundEffects). Etapas y capas en
	-- client/Audio/MinoVoces; el tono baja con la etapa.
	MinoBellow = "rbxassetid://9113626273", -- "Bull Bellows 3" (2.7 s): becerro y joven
	MinoBellowDeep = "rbxassetid://9113625924", -- "Bull Bellows 4" (3.5 s): adulto y final
	MinoGrowl = "rbxassetid://9125470377", -- "Creature Growls Lion Deep Guttural" (2.7 s)
	MinoRumble = "rbxassetid://9116300725", -- "Lion Roar Growl Low Rumble" (5.8 s): final
	MinoSnort = "rbxassetid://9113634896", -- "Bull Goblin Snorts 6" (0.8 s)
	MinoBreath = "rbxassetid://9113630137", -- "Bull Breaths 10" (1.5 s): reposo, pararse
	MinoGrunt = "rbxassetid://9125470306", -- "Creature Growls Lion Deep Guttural" (1.5 s)
	MinoYawn = "rbxassetid://9116307890", -- "Lion Roar Tired 1" (3.3 s)
	MinoSniff = "rbxassetid://9119305209", -- "Sniff Breathe In 5" (2.4 s)
	MinoStepSand = "rbxassetid://9118768256", -- "Sand Impacts 4" (0.8 s)
	MinoStepHeavy = "rbxassetid://9118598240", -- "Rock Hit Dirt Impact 12" (0.8 s)
	MinoSandHit = "rbxassetid://9118767938", -- "Sand Impacts 1" (3.0 s): pisotón y caída
	MinoBoom = "rbxassetid://9125484367", -- "Deep Hits Big Reverberant Booms" (5.1 s)
	MinoSit = "rbxassetid://9113524166", -- "Body Impact 1" (1.1 s): se sienta
	-- Evolución (EvolveFx; de ProSoundEffects, la cuenta de Pro Sound Effects en Roblox)
	EvolveCharge = "rbxassetid://9125635285", -- "Magical Exit Sparkling Pass Bys Clinking Chimes 3" (3.4 s)
	EvolveBurst = "rbxassetid://9126102254", -- "Time Warp Big Explosion Blast Boom Tonal Tail 1" (5.8 s)
	-- Guarida del dragón (ProSoundEffects). Volumen, tono y alcance: client/Ambient/LairAir
	-- y LairGeysers (Sounds.define).
	LairRumble = "rbxassetid://9112823552", -- "Lava Rumble 1" (46 s, bucle): el volcán con lava
	LairBubbles = "rbxassetid://9120306743", -- "Underwater Bubbles 6" (1.9 s), grave: aviso del géiser
	GeyserBurst = "rbxassetid://9117984897", -- "Pyro Fire Ball Burst 2" (3.5 s): revienta el géiser
	-- Música (con licencia de Roblox: APM y DistroKid, se pueden usar en cualquier juego)
	MusicIsland = "rbxassetid://128770946473000", -- "The Fisherman's Small Boat" (2:39)
	MusicCrater = "rbxassetid://1843867314", -- "Tension Repeat Drones 29" (2:04)
	MusicRest = "rbxassetid://9046678292", -- "Work Like A Champion" (2:25)
	-- Cráter
	HorrorAmbience = "rbxassetid://138890398994853", -- ambiente de terror (3:20)
	Thunder = "rbxassetid://139319051979882", -- "Thunder"
	-- Interfaz
	Coins = "rbxassetid://135483737426662", -- "Coin Collect"
	CoinPop = "rbxassetid://135483737426662", -- la misma, aguda y bajita: cada moneda que llega
	Click = "rbxassetid://139719503904449", -- clic de interfaz
	PowerTick = "rbxassetid://137273815815490", -- la misma burbuja de Bite, más aguda
}

return table.freeze(Sounds)
