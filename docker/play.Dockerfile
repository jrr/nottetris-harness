# Adds a VNC server to a headless LÖVE image, for playing by hand.
#   docker build -f docker/play.Dockerfile --build-arg LOVE=0.7.2 -t nottetris-play:0.7.2 docker
ARG LOVE
FROM nottetris-love:${LOVE}
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y x11vnc \
	&& rm -rf /var/lib/apt/lists/*
COPY play.sh /usr/local/bin/harness-play
