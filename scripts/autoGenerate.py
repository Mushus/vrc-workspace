import bpy
import sys
import os

# Basic Operation

def initialize():
    for obj in bpy.data.objects.values():
        obj.select_set(False)
        obj.hide_set(False)
    bpy.context.window.view_layer.objects.active = None

def deselect_all_object():
    bpy.ops.object.select_all(action='DESELECT')


def set_active_object(obj):
    bpy.context.window.view_layer.objects.active = obj
    select_object(obj)
    bpy.ops.object.mode_set(mode = 'OBJECT')


def select_object(obj):
    obj.select_set(True)


def modifier_apply(modifier):
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def shape_key_remove(obj):
    set_active_object(obj)
    bpy.ops.object.shape_key_remove(all=True)


def remove_object(obj):
    bpy.data.objects.remove(obj, do_unlink=True)


def clone_object(obj):
    clone = obj.copy()
    make_single_user(clone)
    clone.parent = obj.parent
    parent_name = obj.parent.name
    collection = find_collection_belong_to(parent_name)
    if collection is not None:
        collection.objects.link(clone)
    return clone

def find_collection_belong_to(obj_name):
    def process(c):
        if obj_name in c.objects:
            return c
        for child in c.children:
            found = process(child)
            if found is not None:
                return found
        return None

    return process(bpy.context.scene.collection)


def join_object():
    bpy.ops.object.join()


def objects_select(objects):
    deselect_all_object()
    for index, obj in enumerate(objects):
        select_object(obj)
        if index == 0:
            set_active_object(obj)


def make_single_user(obj):
    if obj.data.users != 1:
        obj.data = obj.data.copy()


def join_shapes():
    bpy.ops.object.join_shapes()

# Specific Operation


PROCESSABLE_MODIFIER_TYPE_LIST = ['MIRROR', 'SUBSURF']


def processable_object(obj):
    return not obj.name.startswith('_')


def list_process_target_objects():
    return list(filter(processable_object, bpy.data.objects))

def list_proces_target_meshes():
    return list(filter(lambda o: o.type == 'MESH', list_process_target_objects()))

def merge_objects():
    meshes = list_proces_target_meshes()
    root_meshes = list(filter(lambda m: '.' not in m.name, meshes))
    
    for root_mesh in root_meshes:
        deselect_all_object()
        set_active_object(root_mesh)

        prefix = root_mesh.name + '.'
        selected_mesh = [
            mesh for mesh in meshes if mesh.name.startswith(prefix)]
        if len(selected_mesh) == 0:
            continue

        for mesh in selected_mesh:
            select_object(mesh)


        join_object()
        meshes = list_proces_target_meshes()


def apply_modifier_without_shape_key(obj):
    deselect_all_object()
    set_active_object(obj)
    for mod in obj.modifiers:
        if mod.type in PROCESSABLE_MODIFIER_TYPE_LIST:
            try:
                modifier_apply(modifier=mod)
            except RuntimeError:
                pass


def remove_process_target_modifier(obj):
    for mod in obj.modifiers:
        if mod.type in PROCESSABLE_MODIFIER_TYPE_LIST:
            obj.modifiers.remove(mod)


def apply_shape_key(obj, shape_key_name):
    for shape_key in reversed(obj.data.shape_keys.key_blocks):
        if shape_key.name != shape_key_name:
            obj.shape_key_remove(shape_key)
    obj.shape_key_clear()


def extract_shape_keys(obj):

    def extract_shape_key(shape_key):
        clone = clone_object(obj)
        apply_shape_key(clone, shape_key.name)
        return (shape_key.name, clone)

    return dict(map(extract_shape_key, obj.data.shape_keys.key_blocks))


def apply_modifier_with_shape_key(obj):
    shape_key_objs = extract_shape_keys(obj)

    for src_obj in shape_key_objs.values():
        apply_modifier_without_shape_key(src_obj)

    deselect_all_object()

    dst_obj = None
    for shape_key_name, src_obj in shape_key_objs.items():
        if dst_obj is None:
            dst_obj = src_obj
            dst_obj.shape_key_add(name=shape_key_name, from_mix=False)
            set_active_object(dst_obj)
        else:
            select_object(src_obj)
            join_shapes()
            dst_obj.data.shape_keys.key_blocks[-1].name = shape_key_name
            remove_object(src_obj)

    obj.data.name, dst_obj.data.name = dst_obj.data.name, obj.data.name
    obj.data, dst_obj.data = dst_obj.data, obj.data

    remove_process_target_modifier(obj)
    remove_object(dst_obj)


def apply_process_target_modifiers(obj):
    if not obj.modifiers:
        return

    make_single_user(obj)

    if obj.data.shape_keys is None:
        return apply_modifier_without_shape_key(obj)
    else:
        return apply_modifier_with_shape_key(obj)

def apply_objects_modifiers():
    process_targets = list_process_target_objects()
    for obj in process_targets:
        apply_process_target_modifiers(obj)

def remove_target_uvmap(obj):
    if obj.type != 'MESH':
        return
    mesh = obj.data
    for uv in mesh.uv_layers:
        if uv.name.startswith('_'):
            mesh.uv_layers.remove(uv)
        

    

def remove_uvmap():
    process_targets = list_process_target_objects()
    for obj in process_targets:
        remove_target_uvmap(obj)

def read_args():
    argv = sys.argv
    try:
        index = argv.index("--") + 1
    except ValueError:
        index = len(argv)

    argv = argv[index:]
    return argv

def save_as_fbx():
    filepath = os.path.splitext(bpy.data.filepath)[0]+'.fbx'

    process_targets = list_process_target_objects()
    objects_select(process_targets)
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        path_mode='RELATIVE',
        use_selection=True,
        apply_scale_options='FBX_SCALE_UNITS',
        bake_anim=False
    )

# Main

initialize()
apply_objects_modifiers()
remove_uvmap()
merge_objects()
save_as_fbx()

# bpy.ops.wm.save_as_mainfile(filepath="/workspace/out.blend")
