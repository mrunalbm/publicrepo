#!/bin/bash
set -x
echo Hi
##### Phase 4 Update Task Definition and update service to use new definition. this way we can deploy without downtime.
jeknins_pwd=`cat ${HOME}/secret_sudopwd`

if [[ ! -f $WORKSPACE/app_change_status ]]
    then
        echo "File $WORKSPACE/app_change_status not found."
        exit 1
fi

if [[ `cat $WORKSPACE/app_change_status | grep UPLOAD_IMAGE | cut -d '=' -f 2` == "SUCCESS" ]]
then

    PROFILE="dev"
    MODULE_NAME="webapp"
    PROFILE_STRING="--profile ${PROFILE}"

    IMG_VERSION=${BUILD_NUMBER}

    TASK_FAMILY=${PROFILE}-${MODULE_NAME}-task
    SERVICE_NAME=${PROFILE}-${MODULE_NAME}-service
    CLUSTER_NAME=${PROFILE}-WebApp-cluster


    echo getting the task-definition id from given cluster and service
    echo aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}
    aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} ${PROFILE_STRING} > /tmp/aws_services_desc_$$.json
    task_def_id=`jq -r '.services[].taskDefinition' /tmp/aws_services_desc_$$.json`

    echo task_def_id is $task_def_id
    echo getting the container definition under the task-definition json
    aws ecs describe-task-definition --task-definition ${task_def_id} ${PROFILE_STRING} |jq -r ".taskDefinition" |jq "del(.status, .requiresAttributes, .compatibilities, .taskDefinitionArn, .revision)"  > /tmp/aws_cont-def_desc_$$.json

    image_id=`aws ecs describe-task-definition --task-definition ${task_def_id} ${PROFILE_STRING} |jq -r ".taskDefinition.containerDefinitions[].image"`
    echo image_id is: ${image_id}
    curr_image_arn_ver=`echo ${image_id}|awk -F: '{print $NF}'`
    echo curr_image_arn_ver is $curr_image_arn_ver
    curr_image_arn_body=`echo ${image_id}|cut -d: -f1`
    echo curr_image_arn_body is ${curr_image_arn_body}
    new_curr_image_arn_ver=${IMG_VERSION}
    echo new_curr_image_arn_ver is $new_curr_image_arn_ver

    #CONTAINER_DEFINITION_FILE=$(cat /tmp/aws_cont-def_desc_$$.json)
    #CONTAINER_DEFINITION="${CONTAINER_DEFINITION_FILE//${curr_image_arn_body}:${curr_image_arn_ver}/${curr_image_arn_body}:${new_curr_image_arn_ver}}"
    sed -i s";${curr_image_arn_body}:${curr_image_arn_ver};${curr_image_arn_body}:${new_curr_image_arn_ver};g" /tmp/aws_cont-def_desc_$$.json

    ## cont def is having some unwanted things. so removing them before registering
    cat /tmp/aws_cont-def_desc_$$.json | grep -v -e "registeredAt" -e "deregisteredAt" -e "registeredBy" | sed 's/"placementConstraints": \[],/"placementConstraints": \[]/g' > /tmp/aws_cont-def_desc_$$_updated.json

    #Registering new Task Definition
    export TASK_VERSION=$(aws ecs register-task-definition --family ${TASK_FAMILY} --cli-input-json file:///tmp/aws_cont-def_desc_$$_updated.json  ${PROFILE_STRING}  | jq --raw-output '.taskDefinition.revision')
    echo "Registered ECS Task Definition: " $TASK_VERSION

    if [ -n "$TASK_VERSION" ]; then
        echo "Update ECS Cluster: " $CLUSTER_NAME
        echo "Service: " $SERVICE_NAME
        echo "Task Definition: " $TASK_FAMILY:$TASK_VERSION
        
        DEPLOYED_SERVICE=$(aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $TASK_FAMILY:$TASK_VERSION  ${PROFILE_STRING}  | jq --raw-output '.service.serviceName')
        echo "Deployment of $DEPLOYED_SERVICE complete"

    else
        echo "exit: No task definition"
        exit 1
    fi

else
    echo "Either APP_CHANGE=NO or IMAGE_BUILD not SUCCESS or UPLOAD_IMAGE not SUCCESS"
    echo "In this case next phases of pipelines will not do anything."
    exit 0
fi

exit 0