import bpy
import sys

def read_args():
    argv = sys.argv
    try:
        index = argv.index("--") + 1
    except ValueError:
        index = len(argv)

    argv = argv[index:]
    return argv

def remove_all_objects():
    for obj in bpy.data.objects.values():
        obj.select_set(True)
    bpy.ops.object.delete()

def import_fbx(filepath):
    bpy.ops.import_scene.fbx(filepath=filepath,automatic_bone_orientation=True)

def count_tri():
    tris_count = 0
    for o in bpy.context.scene.objects:
        if o.type == 'MESH' and not o.hide_get():
            for p in o.data.polygons:
                if len(p.vertices) > 3:
                    tris_count = tris_count + len(p.vertices) - 2
                else:
                    tris_count = tris_count +1 
    return tris_count

def list_all_shape_key():
    shape_key_name_set = set()
    for o in bpy.context.scene.objects:
        if o.type == 'MESH' and not o.hide_get() and o.data.shape_keys is not None:
            for shape_key in o.data.shape_keys.key_blocks:
                shape_key_name_set.add(shape_key.name)
    return list(shape_key_name_set)

def count_rip_sync():
    shape_keys = list_all_shape_key()
    shape_keys = list(filter(lambda x: x.startswith('vrc.v_'), shape_keys))
    return len(shape_keys)

def count_emotion():
    shape_keys = list_all_shape_key()
    shape_keys = list(filter(lambda x: not x.startswith('vrc.v_'), shape_keys))
    return max(0, len(shape_keys) - 1)
    

args = read_args()
filepath = args[0]

remove_all_objects()
import_fbx(filepath)
print("env:MODEL_TRY_COUNT=\"{}\"".format(count_tri()))
print("env:MODEL_RIP_SYNC_COUNT=\"{}\"".format(count_rip_sync()))
print("env:MODEL_EMOTION_COUNT=\"{}\"".format(count_emotion()))
