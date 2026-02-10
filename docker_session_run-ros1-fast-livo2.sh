#!/bin/bash

IMAGE_NAME='fast-livo2_noetic'
TMUX_SESSION='ros1_session'

DATASET_CONTAINER_DIR='/ros_ws/dataset'
BAG_OUTPUT_CONTAINER='/ros_ws/recordings'

RECORDED_BAG_NAME="recorded-fast-livo2.bag"
HDMAPPING_OUT_NAME="output_hdmapping"

usage() {
  echo "Usage:"
  echo "  $0 <input1.bag> [input2.bag ...] <output_dir>"
  echo
  echo "  The last argument is always the output directory."
  echo "  All preceding arguments are input bag files (played back-to-back)."
  echo
  echo "If no arguments are provided, a GUI file selector will be used."
  exit 1
}

echo "=== FAST-LIVO2 rosbag pipeline ==="

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

if [[ $# -ge 2 ]]; then
  # Last argument is output directory, rest are bag files
  ARGS=("$@")
  BAG_OUTPUT_HOST="${ARGS[-1]}"
  unset 'ARGS[-1]'
  DATASET_HOST_PATHS=("${ARGS[@]}")
elif [[ $# -eq 0 ]]; then
  command -v zenity >/dev/null || {
    echo "Error: zenity is not available"
    exit 1
  }
  DATASET_HOST_PATHS=($(zenity --file-selection --multiple --separator=" " --title="Select BAG file(s)"))
  BAG_OUTPUT_HOST=$(zenity --file-selection --directory --title="Select output directory")
else
  usage
fi

if [[ -z "$BAG_OUTPUT_HOST" || ${#DATASET_HOST_PATHS[@]} -eq 0 ]]; then
  echo "Error: no file or directory selected"
  exit 1
fi

for bag in "${DATASET_HOST_PATHS[@]}"; do
  if [[ ! -f "$bag" ]]; then
    echo "Error: BAG file does not exist: $bag"
    exit 1
  fi
done

mkdir -p "$BAG_OUTPUT_HOST"

BAG_OUTPUT_HOST=$(realpath "$BAG_OUTPUT_HOST")

# Build docker volume mounts and container paths for each bag
DOCKER_VOLUME_ARGS=()
CONTAINER_BAG_PATHS=()
for i in "${!DATASET_HOST_PATHS[@]}"; do
  DATASET_HOST_PATHS[$i]=$(realpath "${DATASET_HOST_PATHS[$i]}")
  CONTAINER_PATH="${DATASET_CONTAINER_DIR}/input_${i}.bag"
  DOCKER_VOLUME_ARGS+=(-v "${DATASET_HOST_PATHS[$i]}":"${CONTAINER_PATH}":ro)
  CONTAINER_BAG_PATHS+=("${CONTAINER_PATH}")
done

ROSBAG_PLAY_ARGS="${CONTAINER_BAG_PATHS[*]}"

echo "Input bags: ${DATASET_HOST_PATHS[*]}"
echo "Output dir: $BAG_OUTPUT_HOST"

xhost +local:docker >/dev/null

docker run -it --rm \
  --network host \
  -e DISPLAY=$DISPLAY \
  -e ROS_HOME=/tmp/.ros \
  -u 1000:1000 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  "${DOCKER_VOLUME_ARGS[@]}" \
  -v "$BAG_OUTPUT_HOST":"$BAG_OUTPUT_CONTAINER" \
  "$IMAGE_NAME" \
  /bin/bash -c '

    tmux new-session -d -s '"$TMUX_SESSION"'

    # ---------- PANEL 0: roscore ----------
    tmux send-keys -t '"$TMUX_SESSION"' '\''
source /opt/ros/noetic/setup.bash
source /ws_livox/devel/setup.bash
source /ros_ws/devel/setup.bash
roscore
'\'' C-m

    # ---------- PANEL 1: set use_sim_time and ROS launch ----------
    tmux split-window -v -t '"$TMUX_SESSION"'
    tmux send-keys -t '"$TMUX_SESSION"' '\''sleep 5
source /opt/ros/noetic/setup.bash
source /ws_livox/devel/setup.bash
source /ros_ws/devel/setup.bash
rosparam set /use_sim_time true
roslaunch fast_livo mapping_avia.launch use_sim_time:=true
'\'' C-m

    # ---------- PANEL 2: rosbag record ----------
    tmux split-window -v -t '"$TMUX_SESSION"'
    tmux send-keys -t '"$TMUX_SESSION"' '\''sleep 2
source /opt/ros/noetic/setup.bash
source /ros_ws/devel/setup.bash
echo "[record] start"
rosbag record /cloud_registered /aft_mapped_to_init -O '"$BAG_OUTPUT_CONTAINER/$RECORDED_BAG_NAME"'
echo "[record] exit"
'\'' C-m

    # ---------- PANEL 3: rosbag play ----------
    tmux split-window -h -t '"$TMUX_SESSION"'
    tmux send-keys -t '"$TMUX_SESSION"' '\''sleep 5
source /opt/ros/noetic/setup.bash
source /ros_ws/devel/setup.bash
echo "[play] start"
rosbag play '"$ROSBAG_PLAY_ARGS"' --clock; tmux wait-for -S BAG_DONE;
echo "[play] done"
'\'' C-m

    # ---------- PANEL 4: controller ----------
    tmux new-window -t '"$TMUX_SESSION"' -n control '\''
source /opt/ros/noetic/setup.bash
source /ros_ws/devel/setup.bash
echo "[control] waiting for play end"
tmux wait-for BAG_DONE
echo "[control] stop record"
tmux send-keys -t '"$TMUX_SESSION"'.2 C-c

sleep 5
rosnode kill -a

sleep 7
pkill -f ros || true
'\''

    tmux attach -t '"$TMUX_SESSION"'
  '

docker run -it --rm \
  --network host \
  -e DISPLAY="$DISPLAY" \
  -e ROS_HOME=/tmp/.ros \
  -u 1000:1000 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$BAG_OUTPUT_HOST":"$BAG_OUTPUT_CONTAINER" \
  "$IMAGE_NAME" \
  /bin/bash -c "
    set -e
    source /opt/ros/noetic/setup.bash
    source /ros_ws/devel/setup.bash
    rosrun fast-livo2-to-hdmapping listener \
      \"$BAG_OUTPUT_CONTAINER/$RECORDED_BAG_NAME\" \
      \"$BAG_OUTPUT_CONTAINER/$HDMAPPING_OUT_NAME-fast-livo2\"
  "

echo "=== DONE ==="
