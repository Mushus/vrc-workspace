#!/usr/bin/env python3
# https://qiita.com/asuuma/items/84be489cf39495a6be24

import sys
import os
import io
import argparse
import os.path
import tarfile
import yaml
import glob
import unityparser

parser = argparse.ArgumentParser(description='Create unitypackage without Unity')

parser.add_argument('-r', '--recursive', action='store_true')
parser.add_argument('targets', nargs='*', help='Target directory or file to pack')
parser.add_argument('-o', '--output', required=True, help='Output unitypackage path')

args = parser.parse_args()

print('Targets:', args.targets)
print('Output unitypackage:', args.output)
print('Is recursive', args.recursive)

for target in args.targets:
    if not os.path.exists(target):
        print("Target doesn't exist: " + target)
        sys.exit(1)

def filter_tarinfo(tarinfo):
    tarinfo.uid = tarinfo.gid = 0
    tarinfo.uname = tarinfo.gname = "root"
    return tarinfo

def add_file(tar, metapath):
    filepath = metapath[0:-5]
    print(filepath)
    with open(metapath, 'r') as f:
        try:
            guid = yaml.safe_load(f)['guid']
        except yaml.YAMLError as exc:
            print(exc)
            return

    # dir
    tarinfo = tarfile.TarInfo(guid)
    tarinfo.type = tarfile.DIRTYPE
    tar.addfile(tarinfo=tarinfo)

    if os.path.isfile(filepath):
        asset_filename = os.path.join(guid, 'asset')

        _, ext = os.path.splitext(filepath)
        print(ext)
        if ext == '.unity':
            with open(filepath, 'r') as f:
                try:
                    filecontent = generate_exported_scene(f)
                except yaml.YAMLError as exc:
                    print(exc)
                    return

            tarinfo = tarfile.TarInfo(asset_filename)
            tarinfo.size = len(filecontent)
            tar.addfile(tarinfo=tarinfo, fileobj=io.BytesIO(filecontent.encode('utf8')))
        else:
            tar.add(filepath, arcname=asset_filename, filter=filter_tarinfo)
    tar.add(metapath, arcname=os.path.join(guid, 'asset.meta'), filter=filter_tarinfo)
    # path: {guid}/pathname
    # text: path of asset
    pathname_content = filepath.encode('utf8')
    tarinfo = tarfile.TarInfo(os.path.join(guid, 'pathname'))
    tarinfo.size = len(pathname_content)
    tar.addfile(tarinfo=tarinfo, fileobj=io.BytesIO(pathname_content))

def generate_exported_scene(scene_fileobject):
    scene_data = scene_fileobject.read()
    scene_fileobject.seek(0)

    for entry in yaml.load_all(scene_fileobject, Loader=unityparser.loader.UnityLoader):
        if entry.__class__.__name__ == 'MonoBehaviour' and 'blueprintId' in entry.get_attrs():
            blueprintId = entry.blueprintId
            if blueprintId is not None:
                print(blueprintId)
                scene_data = scene_data.replace('blueprintId: {}'.format(blueprintId), 'blueprintId:')

    return scene_data

with tarfile.open(args.output, 'w') as tar:
    for target in args.targets:
        add_file(tar, target + '.meta')
        if args.recursive:
            for meta in glob.glob(os.path.join(target, '**/*.meta'), recursive=True):
                add_file(tar, meta)