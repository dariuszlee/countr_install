FROM ubuntu:18.04

COPY ./packages_list.txt .

RUN apt update

ARG DEBIAN_FRONTEND=noninteractive
RUN xargs -a ./packages_list.txt apt-get install -y

RUN git clone https://github.com/apache/incubator-mxnet.git

WORKDIR incubator-mxnet

RUN git checkout 1.5.1
RUN git submodule update --init --recursive
RUN mkdir build
workdir build

RUN cmake -DUSE_CUDA=0 -DCMAKE_BUILD_TYPE=Release -DUSE_OPENCV=0 -DUSE_F16C=0 -DUSE_MKLDNN=0 -DBLAS=Atlas -GNinja ..
RUN ninja -v -j2
RUN ninja install

workdir ..
run mkdir lib
run cp build/libmxnet.so lib
run apt-get install pkg-config -y
run make scalapkg

workdir /
run git clone https://github.com/dariuszlee/countr_facecommon
workdir /countr_facecommon
run mvn install
workdir /

# Install opencv_java342
RUN curl https://codeload.github.com/opencv/opencv/zip/3.4.2 -o opencv342.zip
RUN unzip opencv342.zip
WORKDIR ./opencv-3.4.2/
RUN mkdir build
RUN apt-get install -y ant
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
WORKDIR build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE -D WITH_OPENCL=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_SHARED_LIBS=OFF -D JAVA_INCLUDE_PATH=$JAVA_HOME/include -D JAVA_AWT_LIBRARY=$JAVA_HOME/jre/lib/arm/libawt.so -D JAVA_JVM_LIBRARY=$JAVA_HOME/jre/lib/arm/server/libjvm.so -D CMAKE_INSTALL_PREFIX=/usr ..
RUN make -j10
RUN make install
RUN cp /usr/share/OpenCV/java/libopencv_java342.so /usr/lib/
workdir /

# Download from https://github.com/deepinsight/insightface/wiki/Model-Zoo the model LResNet34-IR and put it into the resource path

run git clone https://github.com/dariuszlee/countr_faceserver
workdir countr_faceserver

copy ./model-r34.zip .
run unzip ./model-r34.zip 
run mv model-r34-amf src/main/resources/

run git checkout migrate_to_mxnet
RUN mvn clean package 

# RUN APP
CMD mvn exec:java -Dexec.mainClass="countr.faceserver.FaceServer"

# This version of the faceserver needs to reference the org.apache.mxnet mxnet-2.11_full:INTERNAL version from the local copy. Located in ~/.m2/repositories/org/apache.mxnet/.....