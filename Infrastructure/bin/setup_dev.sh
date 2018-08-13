#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
echo "setting permissions in project ${GUID}-parks-dev"
oc policy add-role-to-user view --serviceaccount=default -n $GUID-parks-dev
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-dev

MONGODB_DATABASE="mongodb"
MONGODB_USERNAME="mongodb_user"
MONGODB_PASSWORD="mongodb_password"
MONGODB_SERVICE_NAME="mongodb"
MONGODB_ADMIN_PASSWORD="mongodb_admin_password"
MONGODB_VOLUME="4Gi"

echo "Creating  mongodb in project ${GUID}-parks-dev"
oc new-app -f ./Infrastructure/templates/mongo_template.json \
    -n $GUID-parks-dev\
    --param MONGODB_DATABASE=${MONGODB_DATABASE}\
    --param MONGODB_USERNAME=${MONGODB_USERNAME}\
    --param MONGODB_PASSWORD=${MONGODB_PASSWORD}\
    --param MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD}\
    --param MONGODB_VOLUME=${MONGODB_VOLUME}\
    --param MONGODB_SERVICE_NAME=${MONGODB_SERVICE_NAME}


# config map
echo "Creating  configmap in project ${GUID}-parks-dev"
oc create configmap parks-mongodb-config \
    --from-literal=DB_HOST=${MONGODB_SERVICE_NAME}\
    --from-literal=DB_PORT=27017\
    --from-literal=DB_USERNAME=${MONGODB_USERNAME}\
    --from-literal=DB_PASSWORD=${MONGODB_PASSWORD}\
    --from-literal=DB_NAME=${MONGODB_DATABASE}\
    --from-literal=DB_REPLICASET=rs0\
    -n $GUID-parks-dev

echo "Creating apps in project ${GUID}-parks-dev"
oc new-build --binary=true --name=parksmap \
    --image-stream=redhat-openjdk18-openshift:1.2 \
    --allow-missing-imagestream-tags=true -n $GUID-parks-dev

oc new-app $GUID-parks-dev/parksmap:0.0-0 --name=parksmap \
    --allow-missing-imagestream-tags=true \
    --allow-missing-images=true \
    -l type=parksmap-frontend \
    -e APPNAME="ParksMap (Dev)"\
    -n $GUID-parks-dev


oc set triggers dc/parksmap --remove-all -n $GUID-parks-dev
oc create service clusterip parksmap --tcp=8080 -n $GUID-parks-dev
oc expose svc/parksmap --port=8080 --name=parksmap -n $GUID-parks-dev

echo "setting readiness and liveliness probes"
oc set probe dc/parksmap --readiness \
    --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n $GUID-parks-dev
oc set probe dc/parksmap --liveness \
    --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n $GUID-parks-dev