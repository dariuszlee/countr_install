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
run make scalapkg

workdir /
run git clone https://github.com/dariuszlee/countr_facecommon
workdir /countr_facecommon
run mvn install
workdir /

# Install opencv_java342

# Download from https://github.com/deepinsight/insightface/wiki/Model-Zoo the model LResNet34-IR and put it into the resource path
copy ./model-r34.zip .
run git clone https://github.com/dariuszlee/countr_faceserver
workdir countr_faceserver
run git checkout migrate_to_mxnet
run mvn clean package exec:java -Dexec.mainClass="countr.faceserver.FaceServer"

# This version of the faceserver needs to reference the org.apache.mxnet mxnet-2.11_full:INTERNAL version from the local copy. Located in ~/.m2/repositories/org/apache.mxnet/.....