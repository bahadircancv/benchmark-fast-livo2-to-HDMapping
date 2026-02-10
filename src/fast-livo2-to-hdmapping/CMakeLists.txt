cmake_minimum_required(VERSION 3.0.2)
project(fast-livo2-to-hdmapping)

find_package(catkin QUIET COMPONENTS
  roscpp
)

if (catkin_FOUND)
ADD_COMPILE_OPTIONS(-std=c++17 )

## Find catkin macros and libraries
find_package(catkin REQUIRED
        roscpp
        sensor_msgs
        rosbag
        livox_ros_driver
        pcl_ros
)

find_package(PCL 1.8 REQUIRED)
find_package (Eigen3 3.3 REQUIRED NO_MODULE)

catkin_package(
  CATKIN_DEPENDS geometry_msgs nav_msgs roscpp rospy std_msgs rosbag
  DEPENDS EIGEN3 PCL
  INCLUDE_DIRS
)

message("LASzip library")
# LASzip library
add_subdirectory(src/3rdparty/LASzip)
include_directories(src/3rdparty/LASzip/include)

###########
## Build ##
###########

## Specify additional locations of header files
include_directories(
  ${catkin_INCLUDE_DIRS}
  include
  ${EIGEN3_INCLUDE_DIR}
  ${PCL_INCLUDE_DIRS}
  common
)

add_executable(listener src/fast-livo2-subscriber.cpp src/laz_writer.cpp)

## Add cmake target dependencies
add_dependencies(listener ${${PROJECT_NAME}_EXPORTED_TARGETS} ${catkin_EXPORTED_TARGETS} )
## Specify libraries to link
target_link_libraries(listener
  ${catkin_LIBRARIES} Eigen3::Eigen laszip ${catkin_LIBRARIES}
)

else()
  message("catkin not found so skipping this package")
endif()
