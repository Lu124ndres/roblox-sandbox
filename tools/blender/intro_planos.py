"""Planos de la cutscene de entrada (fuente única): el previo de Blender (intro_previo.py) los
filma y el juego reproduce lo que se hornea de acá (intro_camara.hornear_json), muestra por
muestra. Acá van solo los datos; las cuentas de la cámara están en intro_camara.py.

Todo en coordenadas de Roblox (studs, x, y, z). C(dx, y, dz) es relativo al centro del cráter,
donde aparece cada gigante mirando hacia el puente (-Z); la cámara con dz < 0 lo ve de frente.
El cráter es una cueva: adentro, la cámara va sobre el lago (radio < 190) o sobre el paseo
(radio < 235 y y > 31); afuera solo se sale por el túnel (del lado del puente).
Cada plano: duración, puntos de cámara y de mira (curva Catmull-Rom), campo de visión vertical
(grados, como Camera.FieldOfView) al principio y al final, curva de tiempo, temblor de mano y
golpes (segundo, fuerza): sacudón y golpe de lente en los impactos. cartel: el nombre de jefe
del gigante (título, apodo, desde, hasta). Sin keyframes a mano."""

CRATER = (0.0, 722.0)  # WorldLayoutData.craterCenter (x, z)
JUGADOR = (0.0, 8.0, -159.0)  # playa del novato (Retention/TutorialSpawn), mira a -Z
MUESTRAS_POR_SEGUNDO = 30


def C(dx, y, dz):
    return (CRATER[0] + dx, y, CRATER[1] + dz)


# gigante: el que se ve en el plano (None: ninguno). tono: el color de la luz de borde y del
# cielo en ese plano. relampagos: segundos desde el principio del plano.
PLANOS = [
    {
        # Un solo movimiento: de noche sobre el mar, vuela al arco, entra por el túnel y se
        # frena en la cueva justo cuando la orca salta del agua y vuelve a caer.
        "nombre": "entrada",
        "segundos": 7.0,
        "gigante": "Orca",
        "salto": (4.3, 5.4, 6.6),  # sale del agua, cumbre (panza sobre el agua) y cae
        "tono": "noche",
        "adentro": (3.4, "orca"),  # al pasar la puerta del túnel cambia al tono de la cueva
        "camara": [(-520, 40, 60), (-260, 45, 160), (-60, 52, 225), (0, 55, 300), (0, 52, 420),
                   (0, 42, 500), C(35, 18, -180)],
        "mira": [(0, 60, 257), (0, 60, 257), (0, 55, 330), (0, 50, 600), C(0, 40, 0),
                 C(0, 70, 0), C(0, 95, 0)],
        "fov": (35, 62),
        "curva": "suave",
        "temblor": 0.3,
        "relampagos": [0.7, 1.9],
        "golpes": [(0.7, 0.3), (1.9, 0.3), (4.3, 1.0), (6.6, 1.6)],
        "cartel": ("ORCA", "REINA DEL ABISMO", 5.0, 7.0),
    },
    {
        "nombre": "minotauro",
        "segundos": 2.4,
        "gigante": "Minotauro",
        "tono": "minotauro",
        "camara": [C(-30, 4, -120), C(-20, 6, -100)],  # contrapicado: de los pies a la cara
        "mira": [C(0, 20, 0), C(0, 90, 0)],
        "fov": (60, 52),
        "curva": "sale",
        "temblor": 0.4,
        "relampagos": [],
        "golpes": [(0.5, 1.4), (1.2, 0.6)],
        "cartel": ("MINOTAURO", "SEÑOR DEL DESIERTO", 0.7, 2.4),
    },
    {
        "nombre": "dragon",
        "segundos": 2.4,
        "gigante": "DragonMarino",
        "vuela": 60,  # studs sobre el agua
        "tono": "dragon",
        "orbita": {"radio": 160, "alto": 15, "desde": -130, "hasta": -55},
        "mira": [C(0, 90, 0), C(0, 95, 0)],
        "fov": (58, 55),
        "curva": "lineal",
        "temblor": 0.35,
        "relampagos": [],
        "golpes": [(1.0, 1.2)],
        "cartel": ("DRAGÓN MARINO", "FURIA DEL VOLCÁN", 0.7, 2.4),
    },
    {
        "nombre": "zorro",
        "segundos": 2.4,
        "gigante": "ZorroDeAgua",
        "tono": "zorro",
        "camara": [C(-120, 32, -140), C(-70, 33, -150)],
        "mira": [C(0, 60, 0), C(0, 70, 0)],
        "fov": (55, 52),
        "curva": "lineal",
        "temblor": 0.3,
        "relampagos": [],
        "golpes": [(0.8, 0.8)],
        "cartel": ("ZORRO DE AGUA", "ESPÍRITU DEL HIELO", 0.7, 2.4),
    },
    {
        # Un solo movimiento sin corte: se aleja de la orca hacia la puerta del cráter, gira
        # en el túnel (el cráter es una cueva), sale por el arco sobre el puente y baja detrás
        # del novato, donde la toma la cámara del juego (14 atrás, 5 arriba). Amanece.
        "nombre": "revelacion",
        "segundos": 5.5,
        "gigante": "Orca",
        "tono": "amanecer",
        "camara": [C(30, 20, -150), C(0, 40, -215), C(0, 52, -300), C(0, 62, -420),
                   (0, 105, 140), (0, 60, -60), (JUGADOR[0], JUGADOR[1] + 5, JUGADOR[2] + 14)],
        # La mira da la vuelta por un costado: si pasara por la cámara, el giro saltaría.
        "mira": [C(0, 70, 0), C(0, 60, 0), C(120, 55, -280), (0, 50, 150), (0, 10, 0),
                 (0, 8, -120), (JUGADOR[0], JUGADOR[1] + 2, JUGADOR[2] - 10)],
        "fov": (55, 70),  # termina en el campo de visión del juego
        "curva": "suave",
        "temblor": 0.0,
        "relampagos": [],
        "golpes": [(2.4, 0.5)],
        "titulo": (2.4, 4.6),  # segundos del plano en que se ve el título
        "amanece": 2.2,  # desde aquí (al salir por el arco) se hace de día
    },
]

