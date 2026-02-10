FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg2 lsb-release software-properties-common sudo \
    build-essential git cmake \
    python3-pip \
    libceres-dev libeigen3-dev \
    libpcl-dev \
    nlohmann-json3-dev \
    libusb-1.0-0-dev \
    libopencv-dev \
    libfmt-dev \
    tmux \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/ros1.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-desktop-full \
    ros-noetic-geodesy ros-noetic-pcl-ros ros-noetic-nmea-msgs ros-noetic-libg2o \
    python3-rosdep \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone https://github.com/strasdat/Sophus.git && \
    cd Sophus && \
    git checkout a621ff && \
    sed -i \
      -e 's/unit_complex_\.real() = 1\.;/unit_complex_.real(1.);/' \
      -e 's/unit_complex_\.imag() = 0\.;/unit_complex_.imag(0.);/' \
      sophus/so2.cpp && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_CXX_STANDARD=17 && \
    make -j$(nproc) && \
    make install

RUN git clone https://github.com/Livox-SDK/Livox-SDK.git && \
    cd Livox-SDK && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install

WORKDIR /ws_livox

RUN mkdir -p src

WORKDIR /ws_livox/src

RUN git clone https://github.com/Livox-SDK/livox_ros_driver.git

WORKDIR /ws_livox

RUN source /opt/ros/noetic/setup.bash && \
    catkin_make

# Clone vikit dependency (needed by FAST-LIVO2)
WORKDIR /ws_livox/src

RUN git clone https://github.com/uzh-rpg/rpg_vikit.git

WORKDIR /ws_livox

RUN source /opt/ros/noetic/setup.bash && \
    source /ws_livox/devel/setup.bash && \
    catkin_make -DCMAKE_CXX_STANDARD=17

WORKDIR /ros_ws

COPY ./src ./src

RUN source /opt/ros/noetic/setup.bash && \
    source /ws_livox/devel/setup.bash && \
    catkin_make -DCMAKE_CXX_STANDARD=17

ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ros && \
    useradd -m -u $UID -g $GID -s /bin/bash ros

WORKDIR /ros_ws

RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc && \
    echo "source /ws_livox/devel/setup.bash" >> ~/.bashrc && \
    echo "source /ros_ws/devel/setup.bash" >> ~/.bashrc

CMD ["bash"]
