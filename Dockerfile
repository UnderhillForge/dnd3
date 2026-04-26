# syntax=docker/dockerfile:1
# check=error=true

ARG DOCKER_IMAGE=alpine:3.23
FROM $DOCKER_IMAGE AS dev

ENV LUAJIT_VERSION=v2.1

RUN apk add --no-cache git build-base cmake curl-dev zlib-dev zstd-dev \
		sqlite-dev postgresql-dev hiredis-dev leveldb-dev \
		gmp-dev jsoncpp-dev ninja

WORKDIR /usr/src/

ADD https://github.com/jupp0r/prometheus-cpp.git?branch=master /usr/src/prometheus-cpp
ADD https://github.com/libspatialindex/libspatialindex.git?branch=main /usr/src/libspatialindex
ADD --keep-git-dir https://luajit.org/git/luajit.git?branch=${LUAJIT_VERSION} /usr/src/luajit

RUN cd prometheus-cpp && \
		cmake -B build \
			-DCMAKE_INSTALL_PREFIX=/usr/local \
			-DCMAKE_BUILD_TYPE=Release \
			-DENABLE_TESTING=0 \
			-GNinja && \
		cmake --build build && \
		cmake --install build && \
		cd /usr/src/ && \
	cd libspatialindex && \
		cmake -B build \
			-DCMAKE_INSTALL_PREFIX=/usr/local && \
		cmake --build build && \
		cmake --install build && \
		cd /usr/src/ && \
	cd luajit && \
		make amalg && make install && \
	cd /usr/src/

FROM dev AS builder

COPY .git /usr/src/dnd3/.git
COPY CMakeLists.txt /usr/src/dnd3/CMakeLists.txt
COPY README.md /usr/src/dnd3/README.md
COPY dnd3.conf.example /usr/src/dnd3/dnd3.conf.example
COPY builtin /usr/src/dnd3/builtin
COPY cmake /usr/src/dnd3/cmake
COPY doc /usr/src/dnd3/doc
COPY fonts /usr/src/dnd3/fonts
COPY lib /usr/src/dnd3/lib
COPY misc /usr/src/dnd3/misc
COPY po /usr/src/dnd3/po
COPY src /usr/src/dnd3/src
COPY irr /usr/src/dnd3/irr
COPY textures /usr/src/dnd3/textures

WORKDIR /usr/src/dnd3
RUN cmake -B build \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SERVER=TRUE \
		-DENABLE_PROMETHEUS=TRUE \
		-DBUILD_UNITTESTS=FALSE -DBUILD_BENCHMARKS=FALSE \
		-DBUILD_CLIENT=FALSE \
		-GNinja && \
	cmake --build build && \
	cmake --install build

FROM $DOCKER_IMAGE AS runtime

RUN apk add --no-cache curl gmp libstdc++ libgcc libpq jsoncpp zstd-libs \
				sqlite-libs postgresql hiredis leveldb && \
	adduser -D dnd3 --uid 30000 -h /var/lib/dnd3 && \
	chown -R dnd3:dnd3 /var/lib/dnd3

WORKDIR /var/lib/dnd3

COPY --from=builder /usr/local/share/dnd3 /usr/local/share/dnd3
COPY --from=builder /usr/local/bin/luantiserver /usr/local/bin/luantiserver
COPY --from=builder /usr/local/share/doc/dnd3/dnd3.conf.example /etc/dnd3/dnd3.conf
COPY --from=builder /usr/local/lib/libspatialindex* /usr/local/lib/
COPY --from=builder /usr/local/lib/libluajit* /usr/local/lib/
USER dnd3:dnd3

EXPOSE 30000/udp 30000/tcp
VOLUME /var/lib/dnd3/ /etc/dnd3/

ENTRYPOINT ["/usr/local/bin/luantiserver"]
CMD ["--config", "/etc/dnd3/dnd3.conf"]
