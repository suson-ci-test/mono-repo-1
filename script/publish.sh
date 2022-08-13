#!/bin/bash

EW_GIT_ME_TOKEN=$1;
EW_GIT_ME_USER_NAME="EwGitMe";
EW_GIT_ME_EMAIL="ewgitme@gmail.com";

# Type must be one of branch or tag
DEPLOYMENT_TYPE=${2:-"branch"};
# Name must be branch name or tag name
DEPLOYMENT_NAME=${3:-"main"};

DEPENDENCY_PACKAGE_PREFIX=${4:-"mono-repo-1"};
DEPENDENCY_PACKAGE_FILE_NAME=${5:-"composer.json"}

DEPLOYMENT_COMMIT_MESSAGE=${6:-"export from mono-repo-1"};

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
    rm -rf "${SUB_DIR_NAME}/.git";
    mv ${SUB_DIR_NAME} "${SUB_DIR_NAME}_bkp";

    echo "Clone fresh copy from git";
    git clone ${SUB_DIR_REPO_URL} ${SUB_DIR_NAME};

    echo "Copying files from backup dir";
    cp -r "${SUB_DIR_NAME}_bkp/." "${SUB_DIR_NAME}/";

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
        echo "Updating dependency to ${DEPLOYMENT_NAME} on ${DEPENDENCY_PACKAGE_FILE_NAME}";
        sed -i -E "/${DEPENDENCY_PACKAGE_PREFIX}/s/[^name]\": \"(.*?)\"/: \"${DEPLOYMENT_NAME}\"/g" ${DEPENDENCY_PACKAGE_FILE_NAME};
    else
        echo "Checkout branch ${DEPLOYMENT_NAME}";
        git checkout -B ${DEPLOYMENT_NAME};
        echo "Updating dependency to dev-${DEPLOYMENT_NAME} on ${DEPENDENCY_PACKAGE_FILE_NAME}";
        sed -i -E "/${DEPENDENCY_PACKAGE_PREFIX}/s/[^name]\": \"(.*?)\"/: \"dev-${DEPLOYMENT_NAME}\"/g" ${DEPENDENCY_PACKAGE_FILE_NAME};
    fi

    echo "Pushing deployment ${DEPLOYMENT_NAME}";
    # git push origin ${DEPLOYMENT_NAME};

    echo "Cleaning publish work";
    cd "${PROJECT_ROOT_DIR}/src";
    rm -rf ${SUB_DIR_NAME};
    mv "${SUB_DIR_NAME}_bkp" ${SUB_DIR_NAME};
done

