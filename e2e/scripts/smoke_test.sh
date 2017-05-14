#!/bin/bash -e

test_source_repo=$(pwd)
docker_test_repo=/workspace/go/src/github.com/rook/rook
git_smoke_test_directory=github.com/rook/rook/e2e/tests/smoke
git_test_directory=github.com/rook/rook/e2e/tests
container_image=quay.io/quantum/rook-test
tmp_docker_sock_path=/tmp/docker.sock
results_dir=results
results_filename=test.log
temp_archive=forRookImage.tar

#create the rook infrastructure container
rook_infra::create() {
    export id=$(docker run \
        --net=host \
        -d \
        -e GOPATH=/workspace/go \
        -e GOROOT=/usr/lib/go \
        --privileged \
        --security-opt=seccomp:unconfined \
        -v /var/run/docker.sock:${tmp_docker_sock_path} \
        -v ${test_source_repo}:${docker_test_repo} \
        -v /sys:/sys \
        -w ${docker_test_repo}/e2e \
        ${container_image} \
        /sbin/init)

        rc=$?; if [[ $rc != 0 ]]; then set -e; fi
}

#prepare the rook_infra container to run tests
rook_infra::init() {
    echo Creating results directory
    docker exec ${id} mkdir -p ${results_dir}
    rc=$?; if [[ $rc != 0 ]]; then set -e; fi

#    echo Removing infra docker.sock
#    docker exec ${id} rm -rfv /var/run/docker.sock
#    rc=$?; if [[ $rc != 0 ]]; then set -e; fi

#    echo Creating sysmlink to host docker.sock
#    docker exec ${id} ln -s ${tmp_docker_sock_path} /var/run/docker.sock
#    rc=$?; if [[ $rc != 0 ]]; then set -e; fi
#    echo Success...

    echo Installing rook-test-framework dependencies...
    docker exec ${id} /bin/bash -c \
    "glide install"
    rc=$?; if [[ $rc != 0 ]]; then set -e; fi
    echo Success...
}

rook_infra::run_test() {
    local test_name_regex=$1
    local tag_name=$2
    local rook_platform=$3
    local k8s_version=$4

    docker exec -t ${id} /bin/bash -c \
        "go test -timeout 3600s -run ${test_name_regex} ${git_smoke_test_directory} --rook_platform=${rook_platform} --k8s_version=${k8s_version} --rook_version=${tag_name} -v 2>&1 | tee ${results_dir}/${results_filename}"

    rc=$?; if [[ $rc != 0 ]]; then set -e; fi
}

rook_infra::try_copy_docker_image_to_rook_infra() {
    local tag_name=$1

    echo Searching local docker registry for ${tag_name}
    export imageId=$(docker images -q ${tag_name})

    if [ -z "$imageId" ]; then
        echo Image not found
    else
        echo Image found...

        echo Archiving the docker image
        docker save -o ${temp_archive} ${tag_name}
        rc=$?; if [[ $rc != 0 ]]; then set -e; fi
        echo success...

        echo Copying archived image to rook-infra
        docker cp forRookImage.tar ${id}:/${temp_archive}
        rc=$?; if [[ $rc != 0 ]]; then set -e; fi
        echo success...

        echo Importing image into rook-infra image registry
        docker exec ${id} /bin/bash -c "docker load -i /${temp_archive}"
        rc=$?; if [[ $rc != 0 ]]; then set -e; fi
        echo success...
    fi
}

rook_infra::gather_results() {
    echo Gathering results...

    #install junit parser && create junit results
    docker exec ${id} /bin/bash -c \
        "go get -u -f github.com/jstemmer/go-junit-report && cat ${results_dir}/test.log | go-junit-report > ${results_dir}/junit.xml"

    rc=$?; if [[ $rc != 0 ]]; then set -e; fi
}

rook_infra::cleanup() {
    local tag_name=$1
    local rook_platform=$2
    local k8s_version=$3

    #Run clean up tests that runs down on dind script
    docker exec -t ${id} /bin/bash -c \
        "go test -timeout 3600s -run TestRookInfraCleanUp  ${git_test_directory} --rook_platform=${rook_platform} --k8s_version=${k8s_version} --rook_version=${tag_name} -v 2>&1"

    echo Removing rook-test-framework container and images...
    docker kill ${id} || true
    docker rm ${id} || true
#    docker images|grep 'rook-test\|kubeadm-dind-cluster\|ceph/base'|xargs docker rmi > /dev/null 2>&1 || true

}

 if [ -z "$1" ]; then
        tag_name="master-latest"
    else
        tag_name=$1
    fi

    if [ -z "$2" ]; then
        rook_platform="Kubernetes"
    else
        rook_platform=$2
    fi

    if [ -z "$3" ]; then
        k8s_version="v1.6"
    else
        k8s_version=$3
    fi

{ #try

    rook_infra::create
    sleep 10    #need to add code to retry docker info till success
    rook_infra::try_copy_docker_image_to_rook_infra quay.io/rook/rookd:${tag_name}
    rook_infra::try_copy_docker_image_to_rook_infra quay.io/rook/rook:${tag_name}
    rook_infra::init

    rook_infra::run_test SmokeSuite ${tag_name} ${rook_platform} ${k8s_version}

    rook_infra::gather_results

} || { #catch
    rook_infra::gather_results
}

rook_infra::cleanup ${tag_name} ${rook_platform} ${k8s_version}