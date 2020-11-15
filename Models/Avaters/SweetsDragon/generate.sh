#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

docker run \
    -v $REPO_ROOT:/workspace \
    -it blender:latest Models/Avaters/SweetsDragon/SweetsDragon.blend \
    -P ./scripts/autoGenerate.py

cp \
    $REPO_ROOT/Models/Avaters/SweetsDragon/SweetsDragon.fbx \
    $REPO_ROOT/SDK3Avater/Assets/SweetsDragon/Models/SweetsDragon.fbx