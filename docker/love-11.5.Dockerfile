# LÖVE 11.5 built from source, plus a virtual display for headless runs.
# Ubuntu 16.04, as for the earlier versions. LuaJIT 2.1 as for 11.4, built
# from the v2.1 branch as it was at 11.5's release (11.5 updated its LuaJIT).
FROM ubuntu:16.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
		wget ca-certificates automake make libtool g++ pkg-config \
		libsdl2-dev libopenal-dev zlib1g-dev \
		libfreetype6-dev libmodplug-dev libmpg123-dev libvorbis-dev libtheora-dev \
		libgl1-mesa-dev libgl1-mesa-dri xvfb xauth imagemagick \
	&& rm -rf /var/lib/apt/lists/*

ARG LUAJIT=43d0a19158ceabaa51b0462c1ebc97612b420a2e
WORKDIR /build
RUN wget -q https://github.com/LuaJIT/LuaJIT/archive/$LUAJIT.tar.gz \
	&& tar xzf $LUAJIT.tar.gz \
	&& cd LuaJIT-$LUAJIT \
	&& make -j"$(nproc)" PREFIX=/usr/local \
	&& make install PREFIX=/usr/local \
	&& ldconfig \
	&& cd / && rm -rf /build

WORKDIR /build
RUN wget -q https://github.com/love2d/love/archive/refs/tags/11.5.tar.gz \
	&& tar xzf 11.5.tar.gz \
	&& cd love-11.5 \
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
