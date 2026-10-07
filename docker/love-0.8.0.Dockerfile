# LÖVE 0.8.0 built from source, plus a virtual display for headless runs.
# Ubuntu 16.04, as for 0.7.2 (not yet tried on anything newer).
FROM ubuntu:16.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
		wget ca-certificates automake make libtool g++ pkg-config \
		libsdl1.2-dev libopenal-dev liblua5.1-0-dev libdevil-dev libmng-dev \
		libfreetype6-dev libphysfs-dev libmodplug-dev libmpg123-dev libvorbis-dev \
		libgl1-mesa-dev libgl1-mesa-dri xvfb xauth imagemagick \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget -q https://github.com/love2d/love/archive/refs/tags/0.8.0.tar.gz \
	&& tar xzf 0.8.0.tar.gz \
	&& cd love-0.8.0 \
	&& ./platform/unix/automagic \
	&& ./configure \
	&& make -j"$(nproc)" \
	&& make install \
	&& cd / && rm -rf /build

# Software rendering, no audio device.
ENV LIBGL_ALWAYS_SOFTWARE=1 SDL_AUDIODRIVER=dummy ALSOFT_DRIVERS=null
WORKDIR /work

COPY entry.sh /usr/local/bin/harness-entry
