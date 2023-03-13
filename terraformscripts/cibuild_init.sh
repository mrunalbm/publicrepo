#!/bin/bash
set -x
    APP_CHANGE="NO"
    for commit_id in `git rev-list $GIT_PREVIOUS_COMMIT..$GIT_COMMIT`
    do
    	echo  commit_id is $commit_id
		for file in `git diff-tree --no-commit-id --name-only $commit_id`
		do
			echo $file
			if [[ "$file" == "app" ]]
			then 
				APP_CHANGE="YES"
            else
				echo "Nothing to Build  for $file"
		    fi
		done
	done

    if [[ $APP_CHANGE == "YES" ]]
    then
        echo "APP_CHANGE=YES" > $WORKSPACE/app_change_status
        echo "APP_CHANGE=YES"
        echo "In this case next phases of pipelines will build new docker image, upload and update ECS"
    else
        echo "APP_CHANGE=NO" > $WORKSPACE/app_change_status
        echo "APP_CHANGE=NO"
        echo "In this case next phases of pipelines will not do anything."
    fi

    exit 0