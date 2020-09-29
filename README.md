# vrc-workspace

vrchat等で利用するもののうち、公開できるもの全部

# ディレクトリ構成

* SDK3(VRC SDK3 を使用したプロジェクト)
* SDK2(VRC SDK2 を使用したプロジェクト)
* [Model(製作中のモデルデータ)](/Models)

# 環境構築

```
# lfs を使えるようにする
sudo apt install git-lfs
git lfs install

# clone
git clone git@xxxxxxxx

# git-lfs pull
```
* SDK2 にそれぞれ SDK 2 を導入
* SDK3 にそれぞれ SDK 3 Udon を導入
* SDK3Avater にそれぞれ SDK 3 Avater を導入
* Dynamic Bone を Asset Store から導入
* SDK3Avater に ユニティちゃんトゥーンシェーダー を導入
おわり

# temp

```
# build
docker build -t blender ./.docker/blender
# run
docker run -v $PWD:/workspace -it blender:latest ash
# testing
docker run -v $PWD:/workspace -it --entrypoint ash blender:latest

docker run -v $PWD:/workspace blender:latest ./test.blend -P ./scripts/autoGenerate.py
```