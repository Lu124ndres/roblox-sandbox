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
	bones: { [string]: Bone },
	height: number, -- alto del traje en studs
	socket: (bone: string, offset: Vector3) -> Bone?, -- punto pegado al hueso (offset en altos del traje)
	emitter: (emitter: ParticleEmitter) -> (), -- respeta el modo de efectos reducidos
	aura: (size: Vector3, lift: number) -> BasePart, -- pieza invisible del cuerpo (en altos)
	highlight: (fill: Color3, outline: Color3, fillTransparency: number) -> (),
}
export type Style = {
	arms: number, -- amplitud del balanceo de brazos (1 = la animación de Roblox)
	legs: number,
	pose: (ctx: Context) -> { [string]: CFrame }, -- giros extra por hueso
	effects: (fx: Fx) -> (),
}

return {}
