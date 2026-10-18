--!strict
--[[
	Zorro/Conductas

	Lo que hace el zorro de agua cuando nadie le da de comer: el catálogo de la
	biblia (zorro rojo y gato) más los trucos de lucirse, una conducta por archivo
	(Tipos.Conducta). Zorro/Rutina elige una con su peso por etapa y la reproduce de
	u = 0 a 1; su pose se suma a la de reposo. Cada pose entra y sale por el reposo
	(todo en 0 cerca de u = 0 y u = 1), solo suma claves (Zorro/Pose, Cara, Colas) y
	sale de (u, etapa, r): r es el azar de esa vez (Zorro/Azar), igual en todos los
	clientes, y decide lado, repeticiones e intensidad.
		postura   rascarse, lamerse, bostezo, ladear, orejas, dormir, persecucion,
		          olfatear, centinela, hielo
		truco     sacudida, salto (en picada), reverencia, abanico, aullido, fuegos
	Curvas: las curvas y el azar que usan. Giros: el giro del cuerpo de las que dan
	vueltas (persecucion), que suma Rutina al rumbo: una conducta nunca gira al zorro.
]]

local Tipos = require(script.Parent.Tipos)

local Conductas: { Tipos.Conducta } = {
	require(script.Rascarse),
	require(script.Lamerse),
	require(script.Sacudida),
	require(script.Salto),
	require(script.Reverencia),
	require(script.Bostezo),
	require(script.Ladear),
	require(script.Orejas),
	require(script.Dormir),
	require(script.Persecucion),
	require(script.Olfatear),
	require(script.Centinela),
	require(script.Abanico),
	require(script.Aullido),
	require(script.Hielo),
	require(script.Fuegos),
}

return table.freeze(Conductas)
