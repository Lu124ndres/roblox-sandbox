--!strict
--[[
	FedInfo

	Lo que sabe el gigante de cada pez que le llega a la boca (GiantView lo arma
	al llegar cada pez de FeedThrow y lo pasa a body.fed, que lo da a la animación
	de cada gigante: OrcaSwim, MinoStand, DragonFly, ZorroStand):
		from     de dónde vino (el personaje de quien lo alimentó)
		fishId   qué pez (FishCatalog)
		rarity   índice de rareza del pez (1 = común; más alto = más raro)
		isLocal  lo dio el jugador de este cliente
		streak   cuántos peces seguidos lleva comiendo (se corta tras STREAK_GAP s
		         sin comer): sirve para festejar los combos
]]

export type FedInfo = {
	from: Vector3,
	fishId: string,
	rarity: number,
	isLocal: boolean,
	streak: number,
}

return {
	STREAK_GAP = 2.5,
}
