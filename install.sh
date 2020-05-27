export PROJECT_ROOT=$(pwd)
echo "Root is: " $PROJECT_ROOT

apt update

export DEBIAN_FRONTEND=noninteractive
xargs -a ./packages_list.txt apt-get install -y

git clone https://github.com/apache/incubator-mxnet.git

cd $PROJECT_ROOT/incubator-mxnet

git checkout 1.5.1
git submodule update --init --recursive
mkdir build
cd build

cmake -DUSE_CUDA=0 -DCMAKE_BUILD_TYPE=Release -DUSE_OPENCV=0 -DUSE_F16C=0 -DUSE_MKLDNN=0 -DBLAS=Atlas -GNinja ..
ninja -v -j2
ninja install

cd ..
mkdir lib
cp build/libmxnet.so lib
make scalapkg

cd $PROJECT_ROOT
git clone https://github.com/dariuszlee/countr_facecommon
cd $PROJECT_ROOT/countr_facecommon
mvn install
cd $PROJECT_ROOT

# Install opencv_java342
curl https://codeload.github.com/opencv/opencv/zip/3.4.2 -o opencv342.zip
unzip opencv342.zip
cd $PROJECT_ROOT/opencv-3.4.2/
mkdir build
apt-get install -y ant
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE -D WITH_OPENCL=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_SHARED_LIBS=OFF -D JAVA_INCLUDE_PATH=$JAVA_HOME/include -D JAVA_AWT_LIBRARY=$JAVA_HOME/jre/lib/arm/libawt.so -D JAVA_JVM_LIBRARY=$JAVA_HOME/jre/lib/arm/server/libjvm.so -D CMAKE_INSTALL_PREFIX=/usr ..
make -j10
make install
cp /usr/share/OpenCV/java/libopencv_java342.so /usr/lib/
cd $PROJECT_ROOT

# Download from https://github.com/deepinsight/insightface/wiki/Model-Zoo the model LResNet34-IR and put it into the resource path

git clone https://github.com/dariuszlee/countr_faceserver
cd countr_faceserver

unzip $PROJECT_ROOT/model-r34.zip 
mv model-r34-amf src/main/resources/

git checkout migrate_to_mxnet
mvn clean package 

# RUN APP
mvn exec:java -Dexec.mainClass="countr.faceserver.FaceServer"

# This version of the faceserver needs to reference the org.apache.mxnet mxnet-2.11_full:INTERNAL version from the local copy. Located in ~/.m2/repositories/org/apache.mxnet/.....
