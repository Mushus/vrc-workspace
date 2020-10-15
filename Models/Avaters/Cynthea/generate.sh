#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

docker run \
    -v $REPO_ROOT:/workspace \
    -it blender:latest Models/Avaters/Cynthea/Cynthea.blend \
    -P ./scripts/autoGenerate.py

cp \
    $REPO_ROOT/Models/Avaters/Cynthea/Cynthea.fbx \
    $REPO_ROOT/SDK3Avater/Assets/Cynthea/Models/Cynthea.fbx