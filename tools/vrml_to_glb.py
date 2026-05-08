"""
vrml_to_glb.py
--------------
Blender Python script — run via convert_to_glb.ps1, do NOT open this directly.

Usage (handled by the PowerShell launcher):
  blender --background --python vrml_to_glb.py -- <input.wrl> <output.glb>
"""

import bpy
import sys
import os

# ── Parse args passed after the '--' separator ──────────────────────────────
try:
    sep = sys.argv.index("--")
    args = sys.argv[sep + 1:]
except ValueError:
    print("ERROR: No arguments provided after '--'")
    sys.exit(1)

if len(args) < 2:
    print("ERROR: Usage: blender --background --python vrml_to_glb.py -- input.wrl output.glb")
    sys.exit(1)

input_path  = os.path.abspath(args[0])
output_path = os.path.abspath(args[1])

if not os.path.isfile(input_path):
    print(f"ERROR: Input file not found: {input_path}")
    sys.exit(1)

print(f"\n[vrml_to_glb] Input  : {input_path}")
print(f"[vrml_to_glb] Output : {output_path}\n")

# ── Clear default Blender scene ──────────────────────────────────────────────
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=True)

for block in list(bpy.data.meshes) + list(bpy.data.materials) + list(bpy.data.lights):
    try:
        bpy.data.batch_remove([block])
    except Exception:
        pass

# ── Import VRML2 / X3D ───────────────────────────────────────────────────────
# Ensure the X3D/VRML addon is enabled (required in Blender 4.x / 5.x)
addon_name = "io_scene_x3d"
if addon_name not in bpy.context.preferences.addons:
    bpy.ops.preferences.addon_enable(module=addon_name)
    print(f"[vrml_to_glb] Enabled addon: {addon_name}")

result = bpy.ops.import_scene.x3d(
    filepath=input_path,
    axis_forward='-Z',
    axis_up='Y',
)
if 'FINISHED' not in result:
    print(f"ERROR: VRML import failed with result: {result}")
    sys.exit(1)

print(f"[vrml_to_glb] Imported {len(bpy.data.objects)} objects")

# ── Apply transforms so the GLB looks correct in the browser ────────────────
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# ── Export GLB ───────────────────────────────────────────────────────────────
os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)

result = bpy.ops.export_scene.gltf(
    filepath=output_path,
    export_format='GLB',
    export_apply=True,            # Apply modifiers
    export_colors=True,           # Vertex colours (soldermask tint etc.)
    export_materials='EXPORT',    # Full PBR material export
    export_yup=True,              # glTF spec: Y-up
    export_texcoords=True,
    export_normals=True,
    export_tangents=False,
    export_lights=False,
    use_selection=False,
)

if 'FINISHED' not in result:
    print(f"ERROR: GLB export failed with result: {result}")
    sys.exit(1)

size_mb = os.path.getsize(output_path) / 1_048_576
print(f"\n[vrml_to_glb] Done! GLB written: {output_path} ({size_mb:.1f} MB)\n")
