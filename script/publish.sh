#!/bin/bash

EW_GIT_ME_TOKEN=$1;
EW_GIT_ME_USER_NAME="EwGitMe";
EW_GIT_ME_EMAIL="ewgitme@gmail.com";

# Type must be one of branch or tag
DEPLOYMENT_TYPE=${2:-"branch"};
# Name must be branch name or tag name
DEPLOYMENT_NAME=${3:-"main"};

DEPLOYMENT_COMMIT_MESSAGE=${4:-"export from mono-repo"};

PROJECT_ROOT_DIR=$(pwd);

# List of sub repos
declare -A SUB_REPOS;
SUB_REPOS["repo1"]="https://${EW_GIT_ME_TOKEN}@github.com/suson-ci-test/mono-repo-1-sub-1.git";
SUB_REPOS["repo2"]="https://${EW_GIT_ME_TOKEN}@github.com/suson-ci-test/mono-repo-1-sub-2.git";
SUB_REPOS["repo3"]="https://${EW_GIT_ME_TOKEN}@github.com/suson-ci-test/mono-repo-1-sub-3.git";

for key in ${!SUB_REPOS[@]}; do
    SUB_DIR_NAME=${key};
    SUB_DIR_REPO_URL=${SUB_REPOS[${key}]};

    echo "For ${SUB_DIR_NAME}";
    cd "${PROJECT_ROOT_DIR}/src";

    echo "Copying files to backup";
    mv ${SUB_DIR_NAME} "${SUB_DIR_NAME}_bkp";
    git clone ${SUB_DIR_REPO_URL} ${SUB_DIR_NAME};

    echo "Cleaning git init from backup if exist";
    rm -rf "${SUB_DIR_NAME}_bkp/.git";

    echo "Copying files from backup dir";
    cp -r "${SUB_DIR_NAME}_bkp/." "${SUB_DIR_NAME}/";
    rm -rf "${SUB_DIR_NAME}_bkp";

    cd ${PROJECT_ROOT_DIR}/src/${SUB_DIR_NAME};

    echo "Updating git config name and email";
    git config user.name ${EW_GIT_ME_USER_NAME};
    git config user.email ${EW_GIT_ME_EMAIL};

    echo "Adding files to git and commit";
    git add .;
    git commit -m "${DEPLOYMENT_COMMIT_MESSAGE}";

    if [ "${DEPLOYMENT_TYPE}" == "tag" ];
    then
        echo "Tagging ${DEPLOYMENT_NAME}";
        git tag ${DEPLOYMENT_NAME};
    else
       echo "Checkout branch ${DEPLOYMENT_NAME}";
        git checkout -B ${DEPLOYMENT_NAME};
    fi

    echo "Pushing deployment ${DEPLOYMENT_NAME}";
    git push origin ${DEPLOYMENT_NAME};

    echo "Cleaning git init";
    rm -rf ".git";
 
    cd ${PROJECT_ROOT_DIR};
done

