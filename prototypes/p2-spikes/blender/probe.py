# Step-0 pipeline probe (P2 plan §B.2): a tiny skinned flame with two clips, a face part and a hair part.
# Throwaway. Run: Blender --background --factory-startup --python probe.py -- <out.usdz>
import bpy, bmesh, math, os, sys

out = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
here = os.path.dirname(os.path.abspath(__file__))
assets = os.path.join(os.path.dirname(here), "assets")

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.fps = 30
scene.frame_start, scene.frame_end = 1, 90
scene.unit_settings.system = "METRIC"


def material(name, color, emission=0.0, image=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Emission Color"].default_value = (*color, 1)
    bsdf.inputs["Emission Strength"].default_value = emission
    if image:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(image)
        m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        m.node_tree.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    return m


# --- meshes (Blender is Z-up; the exporter converts to Y-up) ---
parts = []
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=0.1, location=(0, 0, 0.1))
body = bpy.context.object
body.scale = (1.0, 0.9, 1.05)
body.data.materials.append(material("FlameBody", (1.0, 0.45, 0.1), 0.4))
parts.append(body)

for i, (x, h) in enumerate([(-0.045, 0.07), (0.0, 0.12), (0.045, 0.07)]):
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.035, depth=h, location=(x, 0, 0.18 + h / 2))
    c = bpy.context.object
    c.data.materials.append(material("FlameHair", (1.0, 0.75, 0.25), 0.6) if i == 0 else bpy.data.materials["FlameHair"])
    parts.append(c)

for side, x in (("L", 0.105), ("R", -0.105)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.03, location=(x, 0, 0.09))
    a = bpy.context.object
    a.name = f"Arm{side}"
    a.data.materials.append(bpy.data.materials["FlameBody"])
    parts.append(a)

bpy.ops.mesh.primitive_plane_add(size=0.1, location=(0, -0.093, 0.115), rotation=(math.radians(90), 0, 0))
face = bpy.context.object
face.data.materials.append(material("FlameFace", (1, 1, 1), 0.0, os.path.join(assets, "face-0.png")))
parts.append(face)

bpy.ops.object.select_all(action="DESELECT")
for p in parts:
    p.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.object.join()
flame = bpy.context.object
flame.name = "Flame"

# --- armature ---
bpy.ops.object.armature_add(location=(0, 0, 0))
rig = bpy.context.object
rig.name = "FlameRig"
bpy.ops.object.mode_set(mode="EDIT")
eb = rig.data.edit_bones
root = eb[0]
root.name, root.head, root.tail = "flame_root", (0, 0, 0), (0, 0, 0.05)


def bone(name, head, tail, parent):
    b = eb.new(name)
    b.head, b.tail, b.parent = head, tail, eb[parent]
    return b


bone("flame_spine", (0, 0, 0.05), (0, 0, 0.15), "flame_root")
bone("flame_head", (0, 0, 0.15), (0, 0, 0.2), "flame_spine")
bone("flame_hair", (0, 0, 0.2), (0, 0, 0.3), "flame_head")
bone("flame_arm_L", (0.08, 0, 0.09), (0.13, 0, 0.09), "flame_spine")
bone("flame_arm_R", (-0.08, 0, 0.09), (-0.13, 0, 0.09), "flame_spine")
bpy.ops.object.mode_set(mode="OBJECT")

# --- deterministic weights by position ---
groups = {n: flame.vertex_groups.new(name=n) for n in
          ("flame_spine", "flame_head", "flame_hair", "flame_arm_L", "flame_arm_R")}
for v in flame.data.vertices:
    x, _, z = v.co
    if abs(x) > 0.085:
        groups["flame_arm_L" if x > 0 else "flame_arm_R"].add([v.index], 1.0, "REPLACE")
    elif z > 0.19:
        groups["flame_hair"].add([v.index], 1.0, "REPLACE")
    elif z > 0.12:
        groups["flame_head"].add([v.index], 1.0, "REPLACE")
    else:
        groups["flame_spine"].add([v.index], 1.0, "REPLACE")
mod = flame.modifiers.new("Armature", "ARMATURE")
mod.object = rig
flame.parent = rig

# --- one timeline, two clips: idle 1-60, cheer 61-90 (rotation/location only, no scale keys) ---
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "XYZ"


def key(b, frame, loc=None, rot=None):
    if loc is not None:
        pb[b].location = loc
        pb[b].keyframe_insert("location", frame=frame)
    if rot is not None:
        pb[b].rotation_euler = [math.radians(a) for a in rot]
        pb[b].keyframe_insert("rotation_euler", frame=frame)


for f, tilt, sway, bob in ((1, 0, -8, 0), (15, 3, 8, 0.004), (30, 0, -8, 0), (45, -3, 8, 0.004), (60, 0, -8, 0)):
    # Bone-local Y runs along the bone (a twist); local Z tilts a vertical bone sideways.
    key("flame_head", f, rot=(0, 0, tilt * 2))
    key("flame_hair", f, rot=(0, 0, sway))
    key("flame_spine", f, loc=(0, bob, 0))
    key("flame_root", f, loc=(0, 0, 0))
    key("flame_arm_L", f, rot=(0, 0, 0))
    key("flame_arm_R", f, rot=(0, 0, 0))
for f, hop, arm in ((61, 0, 0), (68, 0.0, -70), (75, 0.06, -110), (82, 0.0, -70), (90, 0, 0)):
    key("flame_root", f, loc=(0, hop, 0))
    key("flame_arm_L", f, rot=(0, 0, arm))
    key("flame_arm_R", f, rot=(0, 0, -arm))
    key("flame_hair", f, rot=(0, 0, 12 if f == 75 else 0))
bpy.ops.object.mode_set(mode="OBJECT")

bpy.ops.wm.usd_export(
    filepath=out, export_animation=True, export_armatures=True, only_deform_bones=False,
    export_materials=True, generate_preview_surface=True, export_textures=True,
    export_uvmaps=True, export_normals=True, triangulate_meshes=True,
    convert_orientation=True, export_global_forward_selection="NEGATIVE_Z", export_global_up_selection="Y",
    root_prim_path="/root", meters_per_unit=1.0,
)
print("PROBE_EXPORTED", out)
