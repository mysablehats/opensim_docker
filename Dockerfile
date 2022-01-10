FROM ubuntu:18.04

RUN 	apt-get update && \
	apt-get install --yes \ 
	autoconf \
	build-essential \
	clang-3.6 \
	cmake-curses-gui \
	curl \
	freeglut3-dev \
	gfortran \
	git \
	libatlas-base-dev \
	libcurl4-openssl-dev \
	liblapack-dev \
	liblapacke-dev \
	libmetis-dev \
	libpcre3 \
	libpcre3-dev \
	libssl-dev \
	libtool \
	libxi-dev \
	libxmu-dev \
	net-tools \	
	patch \
	pkg-config \
	python3-dev \
	python3-numpy \
	python3-setuptools \
	wget \
	zlib1g-dev 

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

ENV CMAKE_VERSION=3.6.0
RUN 	git clone -b v$CMAKE_VERSION https://gitlab.kitware.com/cmake/cmake.git cmake && \
	cd cmake && \
	./bootstrap --system-curl && \
	make && \
	make install

RUN 	rm -f /usr/bin/cc /usr/bin/c++ && \
	ln -s /usr/bin/clang-3.6 /usr/bin/cc && \
	ln -s /usr/bin/clang++-3.6 /usr/bin/c++

ENV OPENSIM_INSTALL_DIR=/root/opensim_install
#ENV OPENSIM_REPO=https://github.com/mitkof6/opensim-core.git
ENV OPENSIM_REPO=https://github.com/opensim-org/opensim-core.git
#ENV OPENSIM_BRANCH=bindings_timestepper
ENV OPENSIM_BRANCH=master
RUN 	git clone -b $OPENSIM_BRANCH $OPENSIM_REPO
WORKDIR	opensim_dependencies_build
RUN	cmake ../opensim-core/dependencies/ \
      		-DCMAKE_INSTALL_PREFIX='~/opensim_dependencies_install' \
      		-DCMAKE_BUILD_TYPE=RelWithDebInfo && \ 
	make -j12 

WORKDIR /opensim_build

ENV SWIG_VERSION=4.0.2
RUN	wget http://ufpr.dl.sourceforge.net/project/swig/swig/swig-$SWIG_VERSION/swig-$SWIG_VERSION.tar.gz && \
	tar xzf swig-$SWIG_VERSION.tar.gz && \
	cd swig-$SWIG_VERSION/ && \
	./configure --prefix=$HOME/swig && \
	make clean && make && make install
ENV SWIG_PATH=$HOME/swig/bin/swig

ENV PATH=$PATH:/root/swig/bin/
ENV SWIG_DIR=/root/swig/bin
ENV SWIG_EXECUTABLE=/root/swig/bin/swig

RUN 	cmake ../opensim-core \
	      -DCMAKE_INSTALL_PREFIX=$OPENSIM_INSTALL_DIR \
	      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	      -DOPENSIM_DEPENDENCIES_DIR="~/opensim_dependencies_install" \
	      -DBUILD_PYTHON_WRAPPING=ON \
	      -DOPENSIM_PYTHON_VERSION=3 \
	      -DBUILD_JAVA_WRAPPING=OFF \
	      -DWITH_BTK=ON \
	      -DOPENSIM_WITH_TROPTER=OFF

ENV PYTHONPATH=/root/opensim_install/lib/python3.6/site-packages/
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/opensim_install/lib/

WORKDIR /opensim_build
RUN	make -j12
RUN 	make -j12 install && \
	cd /root/opensim_install/lib/python3.6/site-packages/ && \
	python3 setup.py install


