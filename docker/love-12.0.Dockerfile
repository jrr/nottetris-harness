# LÖVE 12.0 (unreleased) built from source, plus a virtual display for
# headless runs. 12 needs SDL3, C++17 and CMake 3.19, so this image is
# Debian 13 instead of the Ubuntu 16.04 the earlier versions use. LuaJIT 2.1
# is Debian's. LÖVE is pinned to a commit on main until 12.0 is released.
FROM debian:trixie

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
		wget ca-certificates cmake g++ pkg-config \
		libsdl3-dev libopenal-dev libluajit-5.1-dev zlib1g-dev \
		libfreetype-dev libharfbuzz-dev libmodplug-dev libvorbis-dev libogg-dev libtheora-dev \
		libgl-dev libgl1-mesa-dri xvfb xauth imagemagick \
	&& rm -rf /var/lib/apt/lists/*

ARG LOVE=b7daef0f7
WORKDIR /build
RUN wget -q -O love.tar.gz https://github.com/love2d/love/archive/$LOVE.tar.gz \
	&& tar xzf love.tar.gz \
	&& cd love-$LOVE* \
	&& cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
	&& cmake --build build --target install -j"$(nproc)" \
	&& ldconfig \
	&& cd / && rm -rf /build

# Software rendering, no audio device.
ENV LIBGL_ALWAYS_SOFTWARE=1 SDL_AUDIODRIVER=dummy ALSOFT_DRIVERS=null
WORKDIR /work

COPY entry.sh /usr/local/bin/harness-entry
