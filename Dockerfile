FROM deepquestai/deepstack:cpu as builder

FROM vcxpz/baseimage-ubuntu:latest

ENV SLEEP_TIME="0.01" \
	CUDA_MODE="False" \
	APPDIR="/app/deepstack" \
	DATA_DIR="/config/" \
	TEMP_PATH="/deeptemp/" \
	PROFILE="desktop_cpu" \
	PYTHON_VERSION="3.7.9"

RUN set -ex && \
	apt-get update && \
	echo "**** install packages ****" && \
	apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		bzip2 \
		ca-certificates \
		curl \
		default-libmysqlclient-dev \
		dpkg-dev \
		ffmpeg \
		file \
		g++ \
		gcc \
		unzip \
		git \
		imagemagick \
		libbluetooth-dev \
		libbz2-dev \
		libc6-dev \
		libcurl4-openssl-dev \
		libdb-dev \
		libevent-dev \
		libffi-dev \
		libgdbm-dev \
		libglib2.0-0 \
		libglib2.0-dev \
		libgmp-dev \
		libjpeg-dev \
		libkrb5-dev \
		liblzma-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmaxminddb-dev \
		libncurses5-dev \
		libncursesw5-dev \
		libpng-dev \
		libpq-dev \
		libreadline-dev \
		libsm6 \
		libsqlite3-dev \
		libssl-dev \
		libtool \
		libwebp-dev \
		libxext6 \
		libxml2-dev \
		libxrender1 \
		libxslt-dev \
		libyaml-dev \
		make \
		mercurial \
		netbase \
		openssh-client \
		patch \
		procps \
		redis-server \
		subversion \
		tk-dev \
		unzip \
		uuid-dev \
		wget \
		xz-utils \
		zlib1g-dev && \
	echo "**** build python ****" && \
	curl -o \
		/tmp/python.tar.xz -L \
		"https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && \
	mkdir -p /usr/src/python && \
	tar xf \
		/tmp/python.tar.xz -C \
		/usr/src/python --strip-components=1 && \
	cd /usr/src/python && \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
	./configure --build="$gnuArch" --enable-loadable-sqlite-extensions --enable-optimizations --enable-option-checking=fatal --enable-shared --with-system-expat --with-system-ffi --without-ensurepip && \
	make -j "$(nproc)" PROFILE_TASK='-m test.regrtest --pgo test_array test_base64 test_binascii test_binhex test_binop test_bytes test_c_locale_coercion test_class test_cmath test_codecs test_compile test_complex test_csv test_decimal test_dict test_float test_fstring test_hashlib test_io test_iter test_json test_long test_math test_memoryview test_pickle test_re test_set test_slice test_struct test_threading test_time test_traceback test_unicode' && \
	make install && \
	rm -rf /usr/src/python && \
	find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.a' \) \) -o \( -type f -a -name 'wininst-*.exe' \) \) -exec rm -rf '{}' + && \
	ldconfig && \
	python3 --version && \
	echo "**** set python symlinks ****" && \
	cd /usr/local/bin && \
	ln -s idle3 idle && \
	ln -s pydoc3 pydoc && \
	ln -s python3 python && \
	ln -s python3-config python-config && \
	echo "**** install pip ****" && \
	curl -o \
		/tmp/get-pip.py -L \
		"https://bootstrap.pypa.io/get-pip.py" && \
	python /tmp/get-pip.py --disable-pip-version-check --no-cache-dir && \
	pip --version && \
	find /usr/local -depth \( \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' + && \
	echo "**** install pip packages ****" && \
	pip3 install --upgrade \
		setuptools \
		pip && \
	pip install \
		torch==1.6.0+cpu \
		torchvision==0.7.0+cpu -f \
		https://download.pytorch.org/whl/torch_stable.html && \
	pip3 install --upgrade \
		Cython \
		Matplotlib \
		PyYAML \
		onnxruntime==0.4.0 \
		opencv-python \
		pillow \
		redis \
		scipy \
		tensorboard \
		tqdm && \
	echo "**** cleanup ****" && \
	apt-get autoremove -y && \
	apt-get clean && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

COPY --from=builder /app /app/deepstack

# copy local files
COPY root/* /

# ports and volumes
EXPOSE 5000
VOLUME /config
