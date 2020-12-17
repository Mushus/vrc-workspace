#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

docker run \
    -v $REPO_ROOT:/workspace \
    -it blender:latest \
    -P ./scripts/getFbxInfo.py \
    -- ./Models/Avaters/Betty/betty.fbx | \
sed -n '/^\env:/p' | \
sed 's/^\env://' > \
test.txt