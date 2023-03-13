#!/bin/bash
#### Phase 2 Build Image
set -x

jeknins_pwd=`cat ${HOME}/secret_sudopwd`

    if [[ -f "${WORKSPACE}/app_change_status" ]]
    then
    APP_CHANGE_VALUE=`cat $WORKSPACE/app_change_status | grep APP_CHANGE | cut -d '=' -f 2`
    if [[ "${APP_CHANGE_VALUE}" == "YES" ]]
    then
        IMAGE_TAG=${BUILD_ID}
        IMAGE_NAME="samplewebapp/webapp"

        # Following 3 commands are to cleanup old image on jenkins server itself on my local laptop
        echo ${jeknins_pwd} | sudo -S docker stop $(echo ${jeknins_pwd} | sudo -S docker ps -q -a)
        echo ${jeknins_pwd} | sudo -S docker rm $(echo ${jeknins_pwd} | sudo -S docker ps -q -a)
        echo ${jeknins_pwd} | sudo -S docker rmi $(echo ${jeknins_pwd} | sudo -S docker images -q -a) --force

        if [[ ! -d $WORKSPACE/terraformscripts ]]
        then
            echo "$WORKSPACE/terraformscripts not found"
            exit 1
        fi
        
        echo ${jeknins_pwd} | sudo -S docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        
        if [[ $? == 0 ]]
        then
            echo "IMAGE_BUILD=SUCCESS" >> $WORKSPACE/app_change_status
            echo "IMAGE_BUILD=SUCCESS"
            echo "Next Phases will upload image and update ECS"
        else
            echo "sudo docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . failed"
            echo "IMAGE_BUILD=FAIL" >> $WORKSPACE/app_change_status
            exit 1
        fi

        # Following is to start new image to test on jenkins server itself on my local laptop
        echo ${jeknins_pwd} | sudo -S docker run -dit -p 8181:80 ${IMAGE_NAME}:${IMAGE_TAG}

    else
        echo "APP_CHANGE=NO"
        echo "In this case next phases of pipelines will not do anything."
        exit 0
    fi
    else
        echo "File $WORKSPACE/app_change_status not found."
        exit 1
    fi
    exit 0
