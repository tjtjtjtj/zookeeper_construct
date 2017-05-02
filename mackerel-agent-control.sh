#!/bin/bash
set -o pipefail

LANG=C

#APIKEYは暗号化ファイルで管理
IMAGE_NAME="mackerel/mackerel-agent"
CONTAINER_NAME="mackerel-agent"
TMPPIPE="/tmp/mackerel-agent_tmppipe_$$"

usage ()
{
  echo "Usage: mackerel_agent_control {run|start|stop|status|update}" 1>&2
  exit 2
}

agent_container_run()
{
  docker run -h $(hostname) \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/mackerel-agent/:/var/lib/mackerel-agent/ \
    -e "apikey=${APIKEY}" \
    -e 'enable_docker_plugin=true' \
    -e 'auto_retirement=0' \
    -e 'opts=-v' \
    --name ${CONTAINER_NAME} \
    --restart=always \
    -d \
    ${IMAGE_NAME}
  RETVAL=$?
  [[ ${RETVAL} -eq 0 ]] && echo "docker run ${CONTAINER_NAME} succeeded." || echo "docker run ${CONTAINER_NAME} failed." 1>&2
  return ${RETVAL}
}

agent_container_start()
{
  docker start ${CONTAINER_NAME}
  RETVAL=$?
  [[ ${RETVAL} -eq 0 ]] && echo "docker strat ${CONTAINER_NAME} succeeded." || echo "docker strat ${CONTAINER_NAME} failed." 1>&2
  return ${RETVAL}
}

agent_container_stop()
{
  docker stop ${CONTAINER_NAME}
  RETVAL=$?
  [[ ${RETVAL} -eq 0 ]] && echo "docker stop ${CONTAINER_NAME} succeeded."|| echo "docker stop ${CONTAINER_NAME} failed." 1>&2
  return ${RETVAL}
}

agent_container_status()
{
  docker inspect \
    --format="Status:{{.State.Status}} StartedAt:{{.State.StartedAt}} Image:{{.Image}}" \
    ${CONTAINER_NAME} | tr " " "\n"
  RETVAL=$?
  [[ ${RETVAL} -eq 0 ]] && echo "docker inspect ${CONTAINER_NAME} succeeded." || echo "docker inspect ${CONTAINER_NAME} failed." 1>&2
  return ${RETVAL}
}

agent_container_remove()
{
  docker rm ${CONTAINER_NAME}
  RETVAL=$?
  [[ ${RETVAL} -eq 0 ]] && echo "${CONTAINER_NAME} remove succeeded" || echo "${CONTAINER_NAME} remove failed." 1>&2
  return ${RETVAL}
}

agent_image_remove()
{
  docker images -f dangling=true -q ${IMAGE_NAME} | docker rmi
  RETVAL=$?
  [[ ${RETVAL} -eq 0 ]] && echo "${CONTAINER_NAME} image remove succeeded" || echo "${CONTAINER_NAME} image remove failed." 1>&2
  return ${RETVAL}
}

cleanup()
{
  [[ -p ${TMPPIPE} ]] && rm -f ${TMPPIPE}
}

agent_image_pull()
{
  #docker pullの状況を標準出力するためにpipeを使用
  trap cleanup EXIT
  trap "trap - EXIT; cleanup; exit -1" 1 2 3 15
  mkfifo ${TMPPIPE}
  cat <${TMPPIPE} &
  IMAGES_LIST=$(docker pull ${IMAGE_NAME} | tee ${TMPPIPE})
  RETVAL=${PIPESTATUS[0]}
  [[ ${RETVAL} -eq 0 ]] || { echo "docker pull ${CONTAINER_NAME} image failed." 1>&2; exit ${RETVAL}; }

  if echo ${IMAGES_LIST} | grep -q "Image is up to date"; then
    echo "${CONTAINER_NAME} image is up to date."
    exit 0
  fi
  return 0
}

agent_container_update()
{
  agent_image_pull
  agent_container_stop
  agent_container_remove
  agent_image_remove 
  #最後にagentをrunできれば成功とする
  agent_container_run 
}

if [[ $# -ne 1 ]]; then
  usage
fi

case "$1" in
  run)
    agent_container_run
    ;;
  start)
    agent_container_start
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
    usage
esac

exit $?
