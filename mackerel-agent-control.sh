#!/bin/sh
set -o pipefail

#api_keyは暗号化ファイルで管理
image_name="mackerel/mackerel-agent"
container_name="mackerel-agent"

func agent_container_run(){
docker run -h `hostname` \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/mackerel-agent/:/var/lib/mackerel-agent/ \
    -e "apikey=${apikey}" \
    -e 'enable_docker_plugin=true' \
    -e 'auto_retirement=0' \
    -e 'opts=-v' \
    --name ${container_name} \
    --restart=always \
    -d \
    -rm \
    ${image_name}
RETVAL=$?
[ ${RETVAL} -eq 0 ] || echo "docker run ${container_name} failed."
return ${RETVAL}
}

func agent_container_stop(){
docker stop ${mackerel-agent}
RETVAL=$?
[ ${RETVAL} -eq 0 ] || echo "docker stop mackerel-agent failed."
return ${RETVAL}
}

func agent_container_status(){
docker inspect \
  --format="Status:{{.State.Status}} StartedAt:{{.State.StartedAt}} Image:{{.Image}}" \
  ${container_name} | tr " " "\n"
RETVAL=$?
[ ${RETVAL} -eq 0 ] || echo "docker inspect mackerel-agent failed."
return ${RETVAL}
}

func agent_image_delete(){
docker images -f dangling=true  -q ${image_name} | docker rmi
RETVAL=$?
[ ${RETVAL} -eq 0 ] || echo "mackerel-agent image delete failed."
return ${RETVAL}
}

func agent_image_pull(){
images_list=`docker pull ${image_name}`
RETVAL=$?
[ ${retval} -eq 0 ] || echo "docker pull failde." ; exit ${retval}

if echo ${images_list} | grep -q "Image is up to date"; then
  echo "mackerel-agent image is up to date."
  exit 0
fi
return 0
}

func agent_container_update(){
agent_image_pull
agent_container_stop
agent_container_run 
agent_image_delete 
}

argument check
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
