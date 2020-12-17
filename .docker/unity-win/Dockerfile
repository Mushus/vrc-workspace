FROM gableroux/unity3d:2018.4.20f1-windows

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

WORKDIR /root/project

ENTRYPOINT ["/entrypoint.sh"]