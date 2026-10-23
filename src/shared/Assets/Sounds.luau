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
	OrcaCall = "rbxassetid://9126210261", -- "Whale Vocal Underwater Talk With Sea Creature 1" (PSE): adulta
	Spout = "rbxasset://sounds/action_swim.mp3",
	BigSplash = "rbxasset://sounds/impact_water.mp3",
	StageUp = "rbxassetid://3454671965", -- fanfarria (badge fanfare)
	Roar = "rbxassetid://9113985604", -- "Creature Roar Mix Of Animals Gate Creaks 1" (PSE, 3.3 s)
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
	MinoCalf = "rbxassetid://9113628549", -- "Bull Bellows 22" (1.9 s), agudo: balido del becerro
	MinoHungry = "rbxassetid://9125470318", -- "Creature Growls Lion Deep Guttural Rumbling 8" (2.7 s)
	MinoHappy = "rbxassetid://9113636328", -- "Bull Grunts Snorts Constant 6" (1.8 s): festejo
	MinoScratch = "rbxassetid://9125408272", -- "Brush Scrub Rubbing On Leather Seat Cushion 1" (2.3 s)
	-- Comer: Minotauro (sus reacciones a cada pez, ProSoundEffects). Capas en
	-- client/Audio/MinoVocesComer.
	MinoGulp = "rbxassetid://9114171955", -- "Drinking Cu Gulping 3" (1.0 s): traga
	MinoBurp = "rbxassetid://9116448360", -- "Male Burp Cu Closed Mouth Quiet 3" (1.5 s)
	MinoYum = "rbxassetid://9113636057", -- "Bull Grunts Snorts Breathing Constant 8" (1.1 s)
	MinoPat = "rbxassetid://9114740689", -- "Gut Hits Bare Skin 13" (1.7 s): se palmea la panza
	MinoDrum = "rbxassetid://9113512609", -- "Body Hit Slaps 4" (1.1 s): tambor en la panza
	MinoClap = "rbxassetid://9114762426", -- "Hand Clap Single Hits 1" (0.8 s): atrapa el pez
	MinoShine = "rbxassetid://9125635442", -- "Magical Exit Sparkling Pass Bys Clinking Chimes 7" (3.5 s)
	-- Dragón (todo de ProSoundEffects, licencia de Roblox). Etapas y capas en
	-- client/Audio/DragonVoces; el tono sigue a la voz o al peso de la etapa.
	DragonScreech = "rbxassetid://9113981940", -- "Creature Mix Pterodactyl Dressed Screams 18" (2.3 s)
	DragonChirp = "rbxassetid://9113981651", -- "Creature Mix Pterodactyl Dressed Screams 14" (0.7 s)
	DragonRoar = "rbxassetid://9113987603", -- "Creature Vocal Giant Crab Monster Roars 1" (6.2 s)
	DragonRoarGrowl = "rbxassetid://9113980319", -- "Creature Mix Giant Crab Monster Roar Growl 1" (4.1 s)
	DragonRumble = "rbxassetid://9120025244", -- "Thunder With Lion Roar Searing Blast 16" (3.4 s)
	DragonGrowl = "rbxassetid://9113973119", -- "Creature Growls Lion 7" (1.4 s)
	DragonHiss = "rbxassetid://9114808824", -- "Hissing Alligator 1" (4.4 s)
	DragonSnort = "rbxassetid://9119628762", -- "Steam Whoosh Phased 1" (2.7 s): resoplido de humo
	DragonSnore = "rbxassetid://9112863325", -- "Rumble Breath Growl 2" (58.9 s, bucle): dormido
	DragonYawn = "rbxassetid://9116308659", -- "Lion Roar Tired 12" (1.5 s)
	DragonFlapSmall = "rbxassetid://9120779671", -- "Wing Flap Up Down Movement 7" (0.8 s)
	DragonFlap = "rbxassetid://9120771864", -- "Wing Flaps 27" (0.8 s): golpe de aire
	DragonFlapHeavy = "rbxassetid://9120773999", -- "Wing Flaps 14" (1.5 s): dragón gigante, cuero
	DragonFlapBurst = "rbxassetid://9120777676", -- "Wing Flaps 6" (2.0 s): varios, despegue
	DragonGust = "rbxassetid://9120720147", -- "Whoosh Giant Swish By 5" (2.5 s): ráfaga
	DragonFold = "rbxassetid://9116257799", -- "Leather Strap 2" (4.4 s): pliega las alas
	DragonFireStart = "rbxassetid://9114432334", -- "Fire Burst 10" (5.9 s)
	DragonFireLick = "rbxassetid://9114463219", -- "Flame Licks 8" (1.7 s)
	DragonFireLoop = "rbxassetid://9112825494", -- "Macho Destructo Fire 1" (36 s, bucle)
	DragonFireWave = "rbxassetid://9114429860", -- "Fire Burst 9" (8.7 s): fuego al cielo
	DragonLand = "rbxassetid://9118588970", -- "Rock Drops 10 Ft High Onto Rocks Dirt 1" (4.0 s)
	DragonDebris = "rbxassetid://9114034406", -- "Debris Rain 1" (4.0 s): grava y ceniza
	DragonBoom = "rbxassetid://9125484367", -- "Deep Hits Big Reverberant Booms" (5.1 s)
	DragonRocks = "rbxassetid://9118690959", -- "Rocks Movement 1" (3.3 s): se acomoda
	DragonHatchling = "rbxassetid://9117236949", -- "Parakeet Chirps 7" (2.9 s), grave: trinos de cría
	DragonBabyRoar = "rbxassetid://9114166971", -- "Dragon Wailing 1" (3.4 s), agudo: rugido de cría
	DragonHungry = "rbxassetid://9116309717", -- "Lions Beastly 2" (6.0 s): gime y jadea de hambre
	DragonJoy = "rbxassetid://9117236763", -- "Parakeet Chirps 3" (3.5 s): trino de gusto
	-- Comer: Dragón (ProSoundEffects). Su animación especial al comer (Dragon/Comer):
	-- capas por etapa en client/Audio/DragonRecetasComer.
	DragonSnap = "rbxassetid://9119055432", -- "Shark Bite Smaller Teeth Snaps 6" (0.6 s): muerde
	DragonGulp = "rbxassetid://9114688489", -- "Gulping Water Glottal Croaks Slurp Water 4" (1.1 s): traga
	DragonPurr = "rbxassetid://9113984339", -- "Creature Purring 1" (1.4 s): gusto, cría y joven
	DragonPurrDeep = "rbxassetid://9113984377", -- "Creature Purr 2" (4.6 s): gusto, adulto y anciano
	DragonTreat = "rbxassetid://9125635442", -- "Magical Exit Sparkling Pass Bys Clinking Chimes 7" (3.5 s)
	DragonFlare = "rbxassetid://9117987817", -- "Pyro Fire Ball Burst 1" (1.5 s): llamarada de un pez raro
	DragonFireRing = "rbxassetid://9117985933", -- "Pyro Fire Ball Burst 7" (1.9 s): anillo de fuego
	-- Comer: Orca (animación especial al comer, OrcaFx/Comida; ProSoundEffects, licencia de
	-- Roblox). Volumen y alcance: client/Audio/OrcaVoces; el tono sigue a la voz de la etapa.
	OrcaSnap = "rbxassetid://9119055965", -- "Shark Bite Smaller Teeth Snaps 5" (0.3 s): chasquido
	OrcaGulp = "rbxassetid://9114688489", -- "Gulping Water Glottal Croaks Slurp Water 4" (1.1 s)
	OrcaHappySpout = "rbxassetid://9120591369", -- "Water Spray 1" (3.1 s): chorro alegre
	OrcaClicks = "rbxassetid://9126135650", -- "Tongue Clicks Classic Clicks From Roof Of Mouth 11" (0.9 s)
	OrcaSong = "rbxassetid://9126210261", -- "Whale Vocal Underwater Talk With Sea Creature 1" (9.9 s)
	OrcaTailSlap = "rbxassetid://9119187654", -- "Slap And Grab 14" (2.7 s): coletazo mojado
	OrcaPartySplash = "rbxassetid://9119476512", -- "Splash Deep Thunking Impact 2" (3.6 s)
	OrcaShine = "rbxassetid://9125635285", -- la de EvolveCharge (3.4 s), aguda: pez raro
	OrcaCalfSqueak = "rbxassetid://9114124037", -- "Dolphins Water Movement 7" (2.4 s): chillidos de cría
	OrcaCallDeep = "rbxassetid://9126210358", -- "Whale Vocal Underwater Talk With Sea Creature 3" (16 s): anciana
	OrcaBlow = "rbxassetid://9120560453", -- "Water Hose Gun 3" (3.9 s): resoplido del espiráculo
	OrcaHungry = "rbxassetid://9113173813", -- "Asian Elephant Squeaks Grunts Blows 1" (4.6 s), grave
	OrcaFull = "rbxassetid://9114123688", -- "Dolphins Water Movement 2" (4.8 s): chillidos alegres
	OrcaGhostWhoosh = "rbxassetid://9125989548", -- "Spirit Whooshes Low End Airy Growls Fast Bys 2" (2.1 s)
	-- Evolución (EvolveFx; de ProSoundEffects, la cuenta de Pro Sound Effects en Roblox)
	EvolveCharge = "rbxassetid://9125635285", -- "Magical Exit Sparkling Pass Bys Clinking Chimes 3" (3.4 s)
	EvolveBurst = "rbxassetid://9126102254", -- "Time Warp Big Explosion Blast Boom Tonal Tail 1" (5.8 s)
	-- Guarida del dragón (ProSoundEffects). Volumen, tono y alcance: client/Ambient/LairAir
	-- y LairGeysers (Sounds.define).
	LairRumble = "rbxassetid://9112823552", -- "Lava Rumble 1" (46 s, bucle): el volcán con lava
	LairBubbles = "rbxassetid://9120306743", -- "Underwater Bubbles 6" (1.9 s), grave: aviso del géiser
	GeyserBurst = "rbxassetid://9117984897", -- "Pyro Fire Ball Burst 2" (3.5 s): revienta el géiser
	-- Comer: Zorro (ProSoundEffects, licencia de Roblox). Capas y tono por etapa en
	-- client/Audio/ZorroVoces; los efectos en client/Giant/ZorroComerFx.
	ZorroYip = "rbxassetid://9113955748", -- "Coyotes Gruff Barking 12" (0.5 s): ladrido corto
	ZorroYipDouble = "rbxassetid://9113955372", -- "Coyotes Gruff Barking 8" (0.8 s): le ladra al jugador
	ZorroGulp = "rbxassetid://9114171960", -- "Drinking Cu Gulping 5" (1.0 s): traga
	ZorroLick = "rbxassetid://9114172114", -- "Drinking Cu Gulping 7" (1.1 s): sorbo, se relame
	ZorroHowlJoy = "rbxassetid://9120790124", -- "Wolf Howl Human- Like 5" (2.2 s): aullido de alegría
	ZorroHowlBig = "rbxassetid://9120790529", -- "Wolf Howl Two Versions 1" (3.5 s): gran festejo
	ZorroBubbles = "rbxassetid://9125408740", -- "Bubble Magic Many Gurgly Floating By Very Wet 1" (2.7 s)
	ZorroShimmer = "rbxassetid://9125635285", -- "Magical Exit Sparkling Pass Bys Clinking Chimes 3" (3.4 s)
	ZorroPaw = "rbxassetid://9117946641", -- "Puddle Stomps Small Water Splashes 3" (0.5 s): pisadas, manotazo
	-- ZorroDeAgua (v2: voz, agua y hielo; todo de ProSoundEffects, licencia de Roblox). Capas
	-- por evento y etapa en client/Audio/ZorroRecetas; tono y volumen en client/Audio/ZorroVoces.
	ZorroWhimper = "rbxassetid://9113952462", -- "Coyote Cu Whimpering Yelping Crying 16" (2.7 s): gañido de cría
	ZorroYelp = "rbxassetid://9113955093", -- "Coyotes Gruff Barking 6" (0.5 s): chillido de cría
	ZorroBark = "rbxassetid://9113956178", -- "Coyotes Gruff Barking 14" (1.1 s): ladrido corto
	ZorroHowlYoung = "rbxassetid://9113950627", -- "Coyote Barks Howls Cries Echo 7" (2.3 s): aullido chico
	ZorroHowlDeep = "rbxassetid://9120790553", -- "Wolf Howl Two Versions 2" (5.2 s): adulto y forma final
	ZorroRumble = "rbxassetid://9114344093", -- "Energy Presence 8" (3.8 s): retumbo grave desde el adulto
	ZorroYawn = "rbxassetid://9116308659", -- "Lion Roar Tired 12" (1.5 s): bostezo (agudo en la cría)
	ZorroSniff = "rbxassetid://9119305209", -- "Sniff Breathe In 5" (2.4 s): olfatea
	ZorroGrowl = "rbxassetid://9120788137", -- "Wolf Growl 3" (2.3 s): gruñido suave (bajito)
	ZorroBite = "rbxassetid://9119055965", -- "Shark Bite Smaller Teeth Snaps 5" (0.3 s): tarascón
	ZorroStepWater = "rbxassetid://9125703168", -- "Mud Puddle Splash Shallow Water Impacts Hits 18" (0.8 s)
	ZorroSplash = "rbxassetid://9117823374", -- "Pool Jumps Splashes Water Impact Swimming 4" (2.3 s): cae de un salto
	ZorroSplashDeep = "rbxassetid://9119476512", -- "Splash Deep Thunking Impact 2" (3.6 s): caída grande
	ZorroShakeSwish = "rbxassetid://9118859146", -- "Seahorse Splash Fast 402" (2.2 s): se sacude
	ZorroDrip = "rbxassetid://9120548576", -- "Water Exit Out Of Water Light Dribble Drip 1" (2.1 s): gotas
	ZorroTailSwish = "rbxassetid://9114455379", -- "Fish Pass By 302" (2.0 s): silbido de las colas
	ZorroWhoosh = "rbxassetid://9120720147", -- "Whoosh Giant Swish By 5" (2.5 s): salto en picada grande
	ZorroIceCrack = "rbxassetid://9125610927", -- "Ice Cubes Drop Falling To Floor Few At A Time 1" (1.2 s)
	ZorroIceCrackBig = "rbxassetid://9114858588", -- "Ice Crackle Large Block Cracks 3" (3.7 s): témpano grande
	ZorroIceTink = "rbxassetid://9114861568", -- "Ice Cube Drops 1" (0.9 s): tintineo de cristales
	-- PSE no tiene zorros: chillido y cacareo ("gekkering") de coyote y ratón con el tono ajustado.
	ZorroScream = "rbxassetid://9113951583", -- "Coyote Cu Whimpering Yelping Crying 3" (2.0 s)
	ZorroGekker = "rbxassetid://9117009021", -- "Mouse Vocal 30" (2.0 s), grave: cacareo rápido
	ZorroHungry = "rbxassetid://9113951479", -- "Coyote Cu Whimpering Yelping Crying 1" (4.1 s)
	ZorroFull = "rbxassetid://9120038042", -- "Tiger Breathing 9" (2.8 s): jadeo contento
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
