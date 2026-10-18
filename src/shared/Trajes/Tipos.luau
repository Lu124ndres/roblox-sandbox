--!strict
-- Tipos de los trajes (aparte para que los estilos no requieran Trajes: sería circular).

export type BoneInfo = {
	name: string,
	parent: string?,
	parts: { string }, -- parte del cuerpo que sigue (R15 primero, después R6)
	limb: string?, -- "arms" o "legs": se le aplica la amplitud del estilo
}
export type Context = {
	now: number,
	speed: number, -- studs/s en el plano
	display: boolean, -- en una vitrina (sin personaje)
}
export type Fx = {
	mesh: MeshPart,
	bones: { [string]: Bone },
	height: number, -- alto del traje en studs
	surface: SurfaceAppearance?, -- la del traje (su brillo: EmissiveStrength)
	rate: () -> number, -- 1 normal, menos (o 0) con efectos reducidos
	socket: (bone: string, offset: Vector3) -> Bone?, -- punto pegado al hueso (offset en altos del traje)
	emitter: (emitter: ParticleEmitter) -> (), -- respeta el modo de efectos reducidos
	aura: (size: Vector3, lift: number) -> BasePart, -- pieza invisible del cuerpo (en altos)
	highlight: (fill: Color3, outline: Color3, fillTransparency: number) -> (),
	-- Gira un hueso que no sigue al cuerpo (la capa): giro en el espacio del personaje,
	-- respecto de su reposo.
	pose: (bone: string, turn: CFrame) -> (),
}
-- Lo que un estilo hace cuadro a cuadro (capa, brillo que late, pisadas).
export type Tick = (ctx: Context) -> ()
export type Style = {
	arms: number, -- amplitud del balanceo de brazos (1 = la animación de Roblox)
	legs: number,
	pose: (ctx: Context) -> { [string]: CFrame }, -- giros extra por hueso
	effects: (fx: Fx) -> Tick?,
}

return {}
