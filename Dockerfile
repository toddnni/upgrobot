#FROM debian:latest@sha256:4eacea30377a698ef8fbec99b6caf01cb150151cbedc8e0b1c3d22f134206f1a
FROM debian:latest

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y install git curl python3 \
    && rm -rf /var/lib/apt/lists/*

COPY src /app
WORKDIR /app

USER 2000
ENV UPGROBOT_CLONE_DIR=/tmp/checkout

CMD /app/upgrobot.sh
