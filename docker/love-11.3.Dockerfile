# LÖVE 11.3 built from source, plus a virtual display for headless runs.
# Ubuntu 16.04, as for the earlier versions. 11 decodes images itself (no
# DevIL) and bundles PhysicsFS. Plain Lua 5.1: Ubuntu 16.04 has no arm64 LuaJIT.
FROM ubuntu:16.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
		wget ca-certificates automake make libtool g++ pkg-config \
		libsdl2-dev libopenal-dev liblua5.1-0-dev zlib1g-dev \
		libfreetype6-dev libmodplug-dev libmpg123-dev libvorbis-dev libtheora-dev \
		libgl1-mesa-dev libgl1-mesa-dri xvfb xauth imagemagick \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget -q https://github.com/love2d/love/archive/refs/tags/11.3.tar.gz \
	&& tar xzf 11.3.tar.gz \
	&& cd love-11.3 \
	&& ./platform/unix/automagic \
	&& ./configure --with-lua=lua5.1 \
	&& make -j"$(nproc)" \
	&& make install \
	&& ldconfig \
	&& cd / && rm -rf /build

# Software rendering, no audio device.
ENV LIBGL_ALWAYS_SOFTWARE=1 SDL_AUDIODRIVER=dummy ALSOFT_DRIVERS=null
WORKDIR /work

COPY entry.sh /usr/local/bin/harness-entry
