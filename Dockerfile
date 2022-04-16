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
	echo "**** download deepstack dependencies ****" && \
	curl -o \
		/tmp/sharedfiles.zip -L \
		"https://deepquest.sfo2.digitaloceanspaces.com/deepstack/shared-files/sharedfiles.zip" && \
	unzip \
		/tmp/sharedfiles.zip -d \
		/out/app/sharedfiles && \
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
	rm -rf \
		/out/app/sharedfiles/face_lite.pt \
		/out/app/sharedfiles/scene.model \
		/out/app/sharedfiles/yolov5s.pt
	
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# runtime stage

FROM vcxpz/baseimage-ubuntu:latest

ARG VERSION="2022.01.1"

ENV DEBIAN_FRONTEND="noninteractive" \
	PIPFLAGS="--no-cache-dir --find-links https://download.pytorch.org/whl/cpu/torch_stable.html" \
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
		python3.7 \
		libsm6 \
		libxext6 \
		libxrender1 \
		libglib2.0-0 \
		ffmpeg \
		redis-server && \
	curl https://bootstrap.pypa.io/get-pip.py | python3.7

RUN set -xe && \
	pip install --no-cache-dir --upgrade \
		pip \
		setuptools && \
	pip install ${PIPFLAGS} \
		torch==1.10.1+cpu \
		torchvision==0.11.2+cpu \
		onnxruntime==0.4.0 \
		redis \
		opencv-python \
		Cython \
		pillow \
		scipy \
		tqdm \
		tensorboard \
		PyYAML \
		Matplotlib \
		easydict \
		future \
		numpy

RUN set -xe && \
	mkdir -p \
		/deeptemp \
		/datastore && \
	cd /app/server && \
	apt-get install -y gcc build-essential && \
	/usr/local/go/bin/go build && \
	echo "**** cleanup ****" && \
	apt-get remove -y --purge \
		gcc build-essential && \
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
