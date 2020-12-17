#!/bin/bash

REPO_ROOT=$(git rev-parse --show-toplevel)

docker run \
    -v $REPO_ROOT:/workspace \
    -it blender:latest Models/Avaters/Catchy/Catchy.blend \
    -P ./scripts/autoGenerate.py

cp \
    $REPO_ROOT/Models/Avaters/Catchy/Catchy.fbx \
    $REPO_ROOT/SDK3Avater/Assets/Catchy/Models/Catchy.fbx