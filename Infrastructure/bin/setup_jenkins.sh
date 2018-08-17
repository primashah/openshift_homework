#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-jenkins

oc new-app jenkins-persistent \
    --param ENABLE_OAUTH=true \
    --param MEMORY_LIMIT=1Gi \
    --param VOLUME_CAPACITY=4Gi \
    -n $GUID-jenkins

# build skopeo slave that will be used by JenkinsFile in the prjoect later
oc new-build --name=jenkins-slave-appdev \
    --dockerfile="$(< ./Infrastructure/templates/docker/skopeo/Dockerfile)" \
    -n $GUID-jenkins


# create pipeline for national  parks
oc create -f ./Infrastructure/templates/nationalparks_pipeline.yaml -n $GUID-jenkins
# set env for national  parks
oc env bc/nationalparks-pipeline GUID=$GUID CLUSTER=$CLUSTER -n $GUID-jenkins

# create pipeline for mlb  parks
oc create -f ./Infrastructure/templates/mlbparks_pipeline.yaml -n $GUID-jenkins
# set env for mlb  parks
oc env bc/mlbparks-pipeline GUID=$GUID CLUSTER=$CLUSTER -n $GUID-jenkins

# create pipeline for parksmap
oc create -f ./Infrastructure/templates/parksmap_pipeline.yaml -n $GUID-jenkins
# set env for parksmap
oc env bc/parksmap-pipeline GUID=$GUID CLUSTER=$CLUSTER -n $GUID-jenkins


# Setup Permissions to prod and dev
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:default -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:default -n ${GUID}-parks-prod
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n ${GUID}-parks-prod


oc set resources dc/jenkins --requests=cpu=1,memory=1Gi --limits=cpu=2,memory=2Gi -n ${GUID}-jenkins