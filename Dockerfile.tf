FROM nvidia/cuda:11.0-cudnn8-devel-ubi8 AS devel

ENV PYTHON_BIN_PATH='/usr/bin/python3.8'
ENV PYTHON_LIB_PATH='/usr/lib/python3.8/site-packages'
ENV TF_NEED_OPENCL_SYCL=0
ENV TF_NEED_ROCM=0
ENV TF_NEED_CUDA=1
ENV TF_NEED_TENSORRT=0
ENV TF_CUDA_PATHS='/usr,/usr/local/cuda'
ENV TF_CUDA_COMPUTE_CAPABILITIES='7.5'
ENV TF_CUDA_CLANG=0
ENV GCC_HOST_COMPILER_PATH='/opt/rh/gcc-toolset-9/root/usr/bin/gcc'
ENV CC_OPT_FLAGS='-march=native -mtune=native -Wno-sign-compare'
ENV TF_SET_ANDROID_WORKSPACE=0

SHELL ["/bin/bash", "-c"]

RUN yum -y install python38 python38-pip python38-devel git which golang gcc-toolset-9 gcc-toolset-9-gcc-c++ && \
source /opt/rh/gcc-toolset-9/enable && \
go get github.com/bazelbuild/bazelisk && \
export PATH=${PATH}:$(go env GOPATH)/bin && \
ln -s $(go env GOPATH)/bin/bazelisk $(go env GOPATH)/bin/bazel && \
ln -s /usr/bin/python3 /usr/bin/python && \
ln -s /usr/bin/pip3 /usr/bin/pip && \
pip install -U pip numpy wheel && \
pip install -U keras_preprocessing --no-deps && \
git clone https://github.com/tensorflow/tensorflow.git && \
cd tensorflow && \
git checkout r2.4 && \
./configure && \
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package && \
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

###
# Copy the built binary into the new image
###
FROM nvidia/cuda:11.0-cudnn8-devel-ubi8
COPY --from=devel /tmp/tensorflow_pkg/tensorflow*.whl /root/
RUN yum -y install python38 python38-pip && \
yum clean all && \
rm -rf /var/cache/yum/* && \
ln -s /usr/bin/pip3 /usr/bin/pip && \
ln -s /usr/bin/python3 /usr/bin/python && \
pip --no-cache-dir install /root/tensorflow*.whl
