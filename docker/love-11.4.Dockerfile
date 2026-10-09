# LÖVE 11.4 built from source, plus a virtual display for headless runs.
# Ubuntu 16.04, as for the earlier versions. 11.4's own builds all moved to
# LuaJIT 2.1, so this one does too: Ubuntu 16.04 has no arm64 LuaJIT, so it's
# built from the v2.1 branch as it was at 11.4's release.
FROM ubuntu:16.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
		wget ca-certificates automake make libtool g++ pkg-config \
		libsdl2-dev libopenal-dev zlib1g-dev \
		libfreetype6-dev libmodplug-dev libmpg123-dev libvorbis-dev libtheora-dev \
		libgl1-mesa-dev libgl1-mesa-dri xvfb xauth imagemagick \
	&& rm -rf /var/lib/apt/lists/*

ARG LUAJIT=a91d0d9d3bba1a936669cfac3244509a0f2ac0e3
WORKDIR /build
RUN wget -q https://github.com/LuaJIT/LuaJIT/archive/$LUAJIT.tar.gz \
	&& tar xzf $LUAJIT.tar.gz \
	&& cd LuaJIT-$LUAJIT \
	&& make -j"$(nproc)" PREFIX=/usr/local \
	&& make install PREFIX=/usr/local \
	&& ldconfig \
	&& cd / && rm -rf /build

WORKDIR /build
RUN wget -q https://github.com/love2d/love/archive/refs/tags/11.4.tar.gz \
	&& tar xzf 11.4.tar.gz \
	&& cd love-11.4 \
	&& ./platform/unix/automagic \
	&& ./configure --with-lua=luajit \
	&& make -j"$(nproc)" \
	&& make install \
	&& ldconfig \
	&& cd / && rm -rf /build

# Software rendering, no audio device.
ENV LIBGL_ALWAYS_SOFTWARE=1 SDL_AUDIODRIVER=dummy ALSOFT_DRIVERS=null
WORKDIR /work

COPY entry.sh /usr/local/bin/harness-entry
