--!strict
--[[
	Zorro/Colas/Tipos

	El contrato de las colas. Solo Zorro/Colas escribe los huesos Cola*_*: las
	conductas, los trucos y comer NO los tocan. Piden un Intent (qué estado y con
	cuánta fuerza) y Zorro/init le pasa el BodyInfo (cómo se mueve el cuerpo).
	Colas mezcla todo con suavidad (≥ 0.3 s: un cambio de golpe en el Intent no se
	ve de golpe), agrega la onda propia de cada cola y resuelve resortes, topes y
	separación.

	Intent (todos opcionales; sin valor = 0, salvo calma = 1):
		calma     cuánto ondulan en reposo (1 normal, 0 quietas, 2 el doble)
		alto      -1..1: colas más arriba (+) o más abajo (-)
		alerta    0..1: abiertas, altas y tensas; la onda se achica y tiembla
		abanico   0..1.5: lucirse, el abanico se abre en cascada del centro hacia
		          afuera con un sobrepaso (las puntas rompen hacia afuera)
		meneo     0..1.6: meneo de contento, de la raíz a la punta
		gusto     0..1: cuánto le gusta lo que come; el meneo se acelera
		envolver  0..1: sentado, las colas bajan a un costado y envuelven las patas
		enroscar  0..1: dormido, enroscadas al costado con la punta hacia la nariz
		lado      -1 o 1: hacia qué costado envuelve o se enrosca (por defecto 1,
		          su derecha)
		latigazo  hora del servidor (GetServerTimeNow) del último latigazo pedido:
		          carga hacia adelante y golpea hacia atrás, de la raíz a la punta.
		          Como sale de la hora del servidor, todos lo ven a la vez.

	BodyInfo (lo calcula Zorro/init; todo en el marco del cuerpo):
		giro      rad/s con que gira el cuerpo (+ a su izquierda): las colas se
		          quedan atrás y después alcanzan
		avance    velocidad sobre el agua (altos del zorro por segundo): las colas
		          se pliegan hacia atrás y se juntan (caminar, correr)
		subida    velocidad vertical (altos por segundo, + sube): en el salto se
		          arrastran; al caer, el frenazo les da un latigazo
		sacudida  0..1: se sacude; una onda fuerte de la raíz a la punta
		bajada    0..1 (opcional): cuánto está la base debajo de la de parado, en
		          fracción del alto (sentado, echado): el piso de las puntas sube igual
]]

export type Intent = {
	calma: number?,
	alto: number?,
	alerta: number?,
	abanico: number?,
	meneo: number?,
	gusto: number?,
	envolver: number?,
	enroscar: number?,
	lado: number?,
	latigazo: number?,
}

export type BodyInfo = {
	giro: number,
	avance: number,
	subida: number,
	sacudida: number,
	bajada: number?,
}

-- La mezcla suavizada que usa Colas por dentro (Intent ya resuelto y suavizado,
-- más lo que sale del cuerpo). abanico va aparte: un resorte por cola (cascada).
export type Mezcla = {
	calma: number,
	alto: number,
	alerta: number,
	meneo: number,
	gusto: number,
	envolver: number,
	enroscar: number,
	lado: number,
	correr: number,
	sacudida: number,
	latigazo: number?,
}

return {}
