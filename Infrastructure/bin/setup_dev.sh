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
MONGODB_USER="mongodb_user"
MONGODB_PASSWORD="mongodb_password"
MONGODB_SERVICE_NAME="mongodb"
MONGODB_ADMIN_PASSWORD="mongodb_admin_password"
VOLUME_CAPACITY="4Gi"

echo "Creating  mongodb in project ${GUID}-parks-dev"
oc new-app -f ./Infrastructure/templates/mongo_template.json \
    -n $GUID-parks-dev\
    --param MONGODB_DATABASE=${MONGODB_DATABASE}\
    --param MONGODB_USER=${MONGODB_USER}\
    --param MONGODB_PASSWORD=${MONGODB_PASSWORD}\
    --param MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD}\
    --param VOLUME_CAPACITY=${VOLUME_CAPACITY}\
    --param DATABASE_SERVICE_NAME=${MONGODB_SERVICE_NAME}


# config map
echo "Creating  configmap in project ${GUID}-parks-dev"
oc create configmap parks-mongodb-config \
    --from-literal=DB_HOST=${MONGODB_SERVICE_NAME}\
    --from-literal=DB_PORT=27017\
    --from-literal=DB_USERNAME=${MONGODB_USER}\
    --from-literal=DB_PASSWORD=${MONGODB_PASSWORD}\
    --from-literal=DB_NAME=${MONGODB_DATABASE}\
    --from-literal=DB_REPLICASET=rs0\
    -n $GUID-parks-dev

echo "Creating parksmap app in project ${GUID}-parks-dev"
oc new-build --binary=true --name=parksmap \
    --image-stream=redhat-openjdk18-openshift:1.2 \
    --allow-missing-imagestream-tags=true -n $GUID-parks-dev

oc new-app $GUID-parks-dev/parksmap:latest --name=parksmap \
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

echo "Creating nationalparks app in project ${GUID}-parks-dev"
oc new-build --binary=true \
        --name=nationalparks \
        --image-stream=redhat-openjdk18-openshift:1.2 \
        --allow-missing-imagestream-tags=true \
        -n $GUID-parks-dev

# deployment config

oc new-app $GUID-parks-dev/nationalparks:latest --name=nationalparks \
    --allow-missing-imagestream-tags=true \
    --allow-missing-images=true \
    -l type=parksmap-backend \
    -e APPNAME="National Parks (Dev)" \
    -e DB_HOST=$MONGODB_SERVICE_NAME \
    -e DB_PORT=27017 \
    -e DB_USERNAME=$MONGODB_USER \
    -e DB_PASSWORD=$MONGODB_PASSWORD \
    -e DB_NAME=$MONGODB_DATABASE \
    -n $GUID-parks-dev


# create environment from configmap
oc set env dc/nationalparks --from configmap/parks-mongodb-config -n $GUID-parks-dev
# remove triggers for auto deployment
oc set triggers dc/nationalparks --remove-all -n $GUID-parks-dev

#create service
oc create service clusterip nationalparks --tcp=8080 -n $GUID-parks-dev
#expose service as route
oc expose svc/nationalparks --port=8080 --name=nationalparks -n $GUID-parks-dev

oc set probe dc/nationalparks --readiness \
    --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n $GUID-parks-dev
oc set probe dc/nationalparks --liveness \
    --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n $GUID-parks-dev

echo "Creating mlbparks app in project ${GUID}-parks-dev"
oc new-build --binary=true --name=mlbparks --image-stream=jboss-eap70-openshift:1.7 \
--allow-missing-imagestream-tags=true \
-n $GUID-parks-dev

oc new-app $GUID-parks-dev/mlbparks:latest --name=mlbparks --allow-missing-imagestream-tags=true \
--allow-missing-images=true \
-l type=parksmap-backend \
 -e APPNAME="MLB Parks (Dev)" \
    -e DB_HOST=$MONGODB_SERVICE_NAME \
    -e DB_PORT=27017 \
    -e DB_USERNAME=$MONGODB_USER \
    -e DB_PASSWORD=$MONGODB_PASSWORD \
    -e DB_NAME=$MONGODB_DATABASE \
    -n $GUID-parks-dev

oc set env dc/mlbparks --from configmap/parks-mongodb-config -n $GUID-parks-dev
oc set triggers dc/mlbparks --remove-all -n $GUID-parks-dev

oc create service clusterip mlbparks --tcp=8080 -n $GUID-parks-dev

oc expose svc/mlbparks --port=8080 --name=mlbparks -n $GUID-parks-dev

oc set probe dc/mlbparks --readiness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n $GUID-parks-dev

oc set probe dc/mlbparks --liveness --get-url=http://:8080/ws/healthz/ --initial-delay-seconds=30 -n $GUID-parks-dev



            
        






