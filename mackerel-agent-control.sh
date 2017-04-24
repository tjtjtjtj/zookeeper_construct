#!/bin/sh
set -o pipefail

#api_keyは暗号化ファイルで管理
IMAGE_NAME="mackerel/mackerel-agent"
CONTAINER_NAME="mackerel-agent"

agent_container_run() {
  docker run -h `hostname` \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/mackerel-agent/:/var/lib/mackerel-agent/ \
    -e "apikey=${apikey}" \
    -e 'enable_docker_plugin=true' \
    -e 'auto_retirement=0' \
    -e 'opts=-v' \
    --name ${CONTAINER_NAME} \
    --restart=always \
    -d \
    -rm \
    ${IMAGE_NAME}
  RETVAL=$?
  [ ${RETVAL} -eq 0 ] || echo "docker run ${CONTAINER_NAME} failed."
  return ${RETVAL}
}

agent_container_stop() {
  docker stop ${CONTAINER_NAME}
  RETVAL=$?
  [ ${RETVAL} -eq 0 ] || echo "docker stop ${CONTAINER_NAME} failed."
  return ${RETVAL}
}

agent_container_status() {
  docker inspect \
    --format="Status:{{.State.Status}} StartedAt:{{.State.StartedAt}} Image:{{.Image}}" \
    ${CONTAINER_NAME} | tr " " "\n"
  RETVAL=$?
  [ ${RETVAL} -eq 0 ] || echo "docker inspect ${CONTAINER_NAME} failed."
  return ${RETVAL}
}

agent_image_delete() {
  docker images -f dangling=true  -q ${IMAGE_NAME} | docker rmi
  RETVAL=$?
  [ ${RETVAL} -eq 0 ] || echo "${CONTAINER_NAME} image delete failed."
  return ${RETVAL}
}

agent_image_pull() {
  IMAGES_LIST=`docker pull ${IMAGE_NAME}`
  RETVAL=$?
  [ ${retval} -eq 0 ] || echo "docker pull ${CONTAINER_NAME} image failed." ; exit ${retval}

  if echo ${IMAGES_LIST} | grep -q "Image is up to date"; then
    echo "${CONTAINER_NAME} image is up to date."
    exit 0
  fi
  return 0
}

agent_container_update() {
  agent_image_pull
  agent_container_stop
  agent_container_run 
  agent_image_delete 
}

argument check
#ここで引数１個のかくにん

case "$1" in
  start)
    agent_container_run
    ;;
  stop)
    agent_container_stop
    ;;
  status)
    agent_container_status
    ;;
  update)
    agent_container_update
    ;;
  *)
    echo $"Usage: $0 {start|stop|status|update}"
    exit 2
esac
exit $?
