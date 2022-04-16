FROM alpine:edge as builder

ARG VERSION="2022.01.1"

RUN set -xe && \
	apk add curl && \
	mkdir -p \
		/out/app/sharedfiles \
		/tmp/sharedfiles \
		/tmp/deepstack \
		/out/usr/local && \
	echo "**** download deepstack ****" && \
	curl -o \
		/tmp/deepstack.tar.gz -L \
		"https://github.com/johnolafenwa/DeepStack/archive/${VERSION}.tar.gz" && \
	tar xf \
		/tmp/deepstack.tar.gz -C \
		/tmp/deepstack --strip-components=1 && \
	echo "**** download deepstack sharedfiles ****" && \
	curl -o \
		/tmp/sharedfiles.zip -L \
		"https://deepquest.sfo2.digitaloceanspaces.com/deepstack/shared-files/sharedfiles.zip" && \
	unzip \
		/tmp/sharedfiles.zip -d \
		/out/app/sharedfiles && \
	echo "**** download go ****" && \
	curl -o \
		/tmp/go1.17.6.linux-amd64.tar.gz -L \
		"https://go.dev/dl/go1.17.6.linux-amd64.tar.gz" && \
	tar xf \
		/tmp/go1.17.6.linux-amd64.tar.gz -C \
		/out/usr/local && \
	echo "**** move files into place ****" && \
	mv /tmp/deepstack/intelligencelayer /out/app/ && \
	mv /tmp/deepstack/server /out/app/ && \
	mv /tmp/deepstack/init.py /out/app/ && \
	echo "**** cleanup ****" && \
	rm -rf \
		/out/app/sharedfiles/face_lite.pt \
		/out/app/sharedfiles/scene.model \
		/out/app/sharedfiles/yolov5s.pt
	
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# runtime stage
FROM vcxpz/baseimage-ubuntu:latest

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Deepstack version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydaz"

ENV PIPFLAGS="--no-cache-dir --find-links https://download.pytorch.org/whl/cpu/torch_stable.html" \
	SLEEP_TIME="0.01" \
	TIMEOUT="60" \
	SEND_LOGS="True" \
	CUDA_MODE="False" \
	APPDIR="/config" \
	DATA_DIR="/datastore" \
	TEMP_PATH="/deeptemp/" \
	PROFILE="desktop_cpu"

COPY --from=builder out/ /

RUN set -xe && \
	echo "**** install runtime packages ****" && \
	echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu focal main" >>/etc/apt/sources.list && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 && \
	apt-get update && \
	apt-get install --no-install-recommends -y \
		build-essential \
		ffmpeg \
		gcc \
		libglib2.0-0 \
		libsm6 \
		libxext6 \
		libxrender1 \
		python3.7 \
		redis-server && \
	curl https://bootstrap.pypa.io/get-pip.py | python3.7 && \
	pip install --no-cache-dir --upgrade \
		pip \
		setuptools && \
	pip install ${PIPFLAGS} \
		Cython \
		Matplotlib \
		PyYAML \
		easydict \
		future \
		numpy \
		onnxruntime==0.4.0 \
		opencv-python \
		pillow \
		redis \
		scipy \
		tensorboard \
		torch==1.10.1+cpu \
		torchvision==0.11.2+cpu \
		tqdm && \
	echo "**** build deepstack server ****" && \
	mkdir -p \
		/deeptemp \
		/datastore && \
	cd /app/server && \
	/usr/local/go/bin/go build && \
	echo "**** cleanup ****" && \
	apt-get remove -y --purge \
		build-essential \
		gcc && \
	apt-get autoremove -y && \
	apt-get clean && \
	rm -rf \
		/tmp/* \
		/usr/local/go \
		/var/lib/apt/lists/* \
		/var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 5000
VOLUME /config
