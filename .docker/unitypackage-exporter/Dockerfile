FROM python:alpine

RUN pip install pyyaml unityparser

COPY script.py /script.py

WORKDIR /workspace

ENTRYPOINT [ "python", "/script.py" ]