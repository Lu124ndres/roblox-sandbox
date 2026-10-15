"""
Arma la orca para animarla desde el juego (OrcaMotion/Rig): esqueleto con
Raiz > Cabeza > Mandibula/Boca/Espiraculo, Raiz > Cola1 > Cola2 > Cola3,
Raiz > AletaIzq/AletaDer/Dorsal, y pesos calculados por posición (cola en
cadena, mandíbula bajo la línea de la boca, aletas pectorales a los lados).
Uso: blender -b --python rig_orca.py -- <OrcaE1.blend reducido> <salida.fbx>
Medidas en las coordenadas del modelo de Meshy reducido (nariz en -Y, Z arriba).
Al importar en Studio: marcar "Mantener huesos de influencia cero".
"""
import bpy, mathutils, json, sys
SRC, OUT = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=SRC)
o=[x for x in bpy.context.scene.objects if x.type=='MESH'][0]
for x in list(bpy.context.scene.objects):
    if x is not o: bpy.data.objects.remove(x)
arm_data=bpy.data.armatures.new("OrcaRig"); arm=bpy.data.objects.new("OrcaRig",arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active=arm; bpy.ops.object.mode_set(mode='EDIT')
C=0.50
B={ # name: (head, tail, parent)
 "Raiz":((0,0.05,C),(0,-0.15,C),None),
 "Cabeza":((0,-0.30,C),(0,-0.55,C),"Raiz"),
 "Mandibula":((0,-0.56,0.54),(0,-0.90,0.48),"Cabeza"),
 "Boca":((0,-0.80,0.53),(0,-0.88,0.53),"Cabeza"),
 "Espiraculo":((0,-0.12,0.92),(0,-0.12,1.00),"Cabeza"),
 "Dorsal":((0,0.08,0.98),(0,0.08,1.06),"Raiz"),
 "Cola1":((0,0.22,C),(0,0.45,C),"Raiz"),
 "Cola2":((0,0.45,C),(0,0.66,0.52),"Cola1"),
 "Cola3":((0,0.66,0.52),(0,0.95,0.62),"Cola2"),
 "AletaIzq":((0.33,-0.28,0.30),(0.65,-0.20,0.08),"Raiz"),
 "AletaDer":((-0.33,-0.28,0.30),(-0.65,-0.20,0.08),"Raiz"),
}
eb=arm_data.edit_bones
for n,(h,t,p) in B.items():
    b=eb.new(n); b.head=h; b.tail=t; b.roll=0
for n,(h,t,p) in B.items():
    if p: eb[n].parent=eb[p]; eb[n].use_connect=False
bpy.ops.object.mode_set(mode='OBJECT')
def clamp(v): return max(0.0,min(1.0,v))
def lerp2(y,a,b): return clamp((y-a)/(b-a))
groups={n:o.vertex_groups.new(name=n) for n in B if n not in("Boca","Espiraculo","Dorsal")}
stats={}
for v in o.data.vertices:
    x,y,z=v.co
    w={}
    # cadena a lo largo del cuerpo
    if y<=-0.48: w={"Cabeza":1}
    elif y<=-0.25: t=lerp2(y,-0.48,-0.25); w={"Cabeza":1-t,"Raiz":t}
    elif y<=0.22: w={"Raiz":1}
    elif y<=0.36: t=lerp2(y,0.22,0.36); w={"Raiz":1-t,"Cola1":t}
    elif y<=0.54: t=lerp2(y,0.36,0.54); w={"Cola1":1-t,"Cola2":t}
    elif y<=0.72: t=lerp2(y,0.54,0.72); w={"Cola2":1-t,"Cola3":t}
    else: w={"Cola3":1}
    # mandíbula
    if y<-0.50 and z<0.53:
        wj=clamp((-0.50-y)/0.08)
        w={k:val*(1-wj) for k,val in w.items()}; w["Mandibula"]=w.get("Mandibula",0)+wj
    # aletas pectorales
    if z<0.40 and -0.47<y<-0.03:
        wf=clamp((abs(x)-0.32)/0.10)
        if wf>0:
            side="AletaIzq" if x>0 else "AletaDer"
            w={k:val*(1-wf) for k,val in w.items()}; w[side]=wf
    for k,val in w.items():
        if val>1e-4:
            groups[k].add([v.index],val,'REPLACE'); stats[k]=stats.get(k,0)+1
o.parent=arm
mod=o.modifiers.new("Armature","ARMATURE"); mod.object=arm
print(json.dumps(stats))
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); arm.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, apply_scale_options="FBX_SCALE_UNITS",
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y", bake_space_transform=False,
    mesh_smooth_type="FACE", add_leaf_bones=False, use_armature_deform_only=False, bake_anim=False,
    primary_bone_axis='Y', secondary_bone_axis='X', object_types={'ARMATURE','MESH'})
