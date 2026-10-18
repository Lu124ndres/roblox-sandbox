r"""
Los números del cuerpo del Zorro de agua v2: copia de src/shared/Zorro/Patas/Ajustes.luau (y
Pose.CROUCH_DROP), con los mismos nombres en mayúsculas. Lo carga zorro_v2_poses_cuerpo.py; los
buscadores del scratchpad los cambian aquí y, medidos, se pasan a Ajustes.luau.
"""
# --- Pose (Pose.CROUCH_DROP) y Patas/Ajustes: comunes ---
CROUCH_DROP = 0.035
SETTLE = 0.006
STRETCH_DROP = 0.02
WALK_DROP = 0.012
BOB = 0.004
SIT = (0.45, 0.05, 0.2)
HEAD_LEVEL = 0.8
SPINE_MAX = 0.25
CURL_SPINE = 0.3
STRETCH_TRUNK = (0.0, -0.12, 0.1)
DUTY = 0.7
GAIT = {"HIzq": 0.0, "FIzq": 0.25, "HDer": 0.5, "FDer": 0.75}
LIFT_U, LIFT_CURL = 0.14, -0.35
LIFT_UH, LIFT_CURL_H = 0.12, -0.5
FOLD_BETA, FOLD_RANGE = 1.45, 0.45
STRETCH_BETA, STRETCH_BACK = 0.4, 0.25
LIE_WRIST = 0.8
SIT_SHOULDER = -0.42
POUNCE_IN = 0.05
POUNCE_F = (0.0, 0.75, 0.0, -0.08)
POUNCE_H = (-0.25, 0.3, 0.0, -0.4)
SCRATCH_BEAT = (0.25, -0.2)
# Zorro/Habitos: zancada (altos por paso completo), la misma con que la rutina da walkPhase.
ZANCADA = {1: 0.3, 2: 0.24, 3: 0.24, 4: 0.24}

# --- Patas/Ajustes: por etapa (medido con este archivo) ---
ETAPAS = {
    1: dict(sitDrop=0.072, lieDrop=0.092, walkLift=(0.8, 0.3), sitPaw=1.0, sitFront=0.125, liePaw=0.966,
            lieReach=1.222, bowReach=0.084, bowWrist=0.05, bowMax=1.2, curlHead=(1.8, -0.115),
            scratchLeg=(1.11, 0.777, -0.4, 1.314, -0.834), scratchHead=(0.25, 0.4, 0.12),
            pawStand=(0.45, 0.9, -0.6, -0.45, 0.2), pawSit=(0.215, 0.975, -0.103, -0.6, 0.17),
            pawHeadStand=(0.138, -0.45), pawHeadSit=(0.184, -0.15), pawHunch=0.27, foldPow=2.0, pawSitMax=1.0),
    2: dict(sitDrop=0.16, lieDrop=0.159, walkLift=(0.8, 0.6), sitPaw=0.63, sitFront=0.318, liePaw=0.808,
            lieReach=1.042, bowReach=0.509, bowWrist=0.0, bowMax=1.2, curlHead=(1.8, -0.732),
            scratchLeg=(1.199, 0.918, 0.25, 1.343, -1.269), scratchHead=(0.186, 0.3, 0.3),
            pawStand=(0.2, 1.1, 0.113, 0.35, 0.475), pawSit=(0.215, 1.016, 0.3, 0.275, 0.384),
            pawHeadStand=(-0.1, -0.613), pawHeadSit=(-0.012, -0.197), pawHunch=0.196, foldPow=1.0, pawSitMax=1.0),
    3: dict(sitDrop=0.16, lieDrop=0.161, walkLift=(0.8, 0.6), sitPaw=0.7, sitFront=0.103, liePaw=0.85,
            lieReach=0.89, bowReach=0.4, bowWrist=0.042, bowMax=1.2, curlHead=(1.8, -0.42),
            scratchLeg=(1.11, 0.66, 0.25, 1.07, -0.9), scratchHead=(0.337, 0.3, 0.35),
            pawStand=(0.7, 1.3, -1.0, 0.5, 0.275), pawSit=(0.54, 1.3, -0.89, 0.65, 0.29),
            pawHeadStand=(0.137, -0.401), pawHeadSit=(0.1, 0.038), pawHunch=0.0, foldPow=1.0, pawSitMax=0.6),
    4: dict(sitDrop=0.13, lieDrop=0.092, walkLift=(0.8, 0.6), sitPaw=0.9, sitFront=0.179, liePaw=0.762,
            lieReach=0.538, bowReach=0.6, bowWrist=0.0, bowMax=0.6, curlHead=(1.8, -0.522),
            scratchLeg=(1.555, 0.941, -0.4, 1.656, -1.277), scratchHead=(0.381, 0.3, 0.35),
            pawStand=(0.45, 1.381, -0.6, 0.45, 0.219), pawSit=(0.215, 1.6, -0.949, 0.7, 0.234),
            pawHeadStand=(0.231, -0.37), pawHeadSit=(0.231, -0.306), pawHunch=0.372, foldPow=1.0, pawSitMax=0.55),
}
