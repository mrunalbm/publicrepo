#!/bin/bash
set -x
#### Phase3 Uploading Image to AWS ECR

jeknins_pwd=`cat ${HOME}/secret_sudopwd`

    if [[ ! -f $WORKSPACE/app_change_status ]]
    then
        echo "File $WORKSPACE/app_change_status not found."
        exit 1
    fi

    if [[ `cat $WORKSPACE/app_change_status | grep IMAGE_BUILD | cut -d '=' -f 2` == "SUCCESS" ]]
    then
        IMAGE_TAG=${BUILD_ID}
        REMOTE_IMAGE_NAME="webapp"
        IMAGE_NAME="samplewebapp/webapp"
        
        if [[ ! -f ${HOME}/.aws/ecr_details ]]
        then
            echo "${HOME}/.aws/ecr_details not found"
            exit 1
        fi

        AWS_ECR=`cat ${HOME}/.aws/ecr_details | grep ^dev | cut -d ',' -f 2`

        if [[ -z $AWS_ECR ]]
        then
            echo "No record for environment dev found under file ${HOME}/.aws/ecr_details"
            exit 1
        fi

        echo ${jeknins_pwd} | sudo -S docker ps

        #aws ecr get-login --no-include-email --profile dev
        aws ecr get-login-password --profile dev | sudo docker login --username AWS --password-stdin ${AWS_ECR}

        if [[ $? != 0 ]]
        then
            echo "Login to ECR ${AWS_ECR} failed "
            exit 1
        fi

        ## Removing latest tag from last image.
        aws ecr batch-delete-image --repository-name webapp --image-ids imageTag=latest

        if [[ $? != 0 ]]
        then
            echo "Failed to remove tag latest from last image"
            exit 1
        fi

        ## Pushing new image to ECR with BUILD_ID as Tag
        sudo docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${AWS_ECR}/${REMOTE_IMAGE_NAME}:${BUILD_ID}
        sudo docker push ${AWS_ECR}/${REMOTE_IMAGE_NAME}:${BUILD_ID}

        if [[ $? != 0 ]]
        then
            echo "Failed to push image to ${AWS_ECR}/${REMOTE_IMAGE_NAME}:${BUILD_ID} "
            exit 1
        fi

        ## Pushing new image to ECR with latest as Tag. This basically will mark same image as BUILD_ID, latest
        sudo docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${AWS_ECR}/${REMOTE_IMAGE_NAME}:latest
        sudo docker push ${AWS_ECR}/${REMOTE_IMAGE_NAME}:latest

        if [[ $? != 0 ]]
        then
            echo "Failed to push image to ${AWS_ECR}/${REMOTE_IMAGE_NAME}:latest"
        fi
        echo "UPLOAD_IMAGE=SUCCESS" >> $WORKSPACE/app_change_status
        echo "UPLOAD_IMAGE=SUCCESS"
        echo "In this case next phases of pipelines will register new task definition and update service."

    else
        echo "Either APP_CHANGE=NO or IMAGE_BUILD not SUCCESS"
        echo "In this case next phases of pipelines will not do anything."
        exit 0
    fi

    exit 0