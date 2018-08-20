#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Studentls

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

PROJECT_NAME=${GUID}-parks-prod
MONGO_TMPL=./Infrastructure/templates/mongo_statefulset_template.yaml
PARKSMAP_TMPL=./Infrastructure/templates/parksmap_prod_template.yaml
NATIONALPARKS_TMPL=./Infrastructure/templates/nationalparks_prod_template.yaml
MLBPARKS_TMPL=./Infrastructure/templates/mlbparks_prod_template.yaml
MONGODB_POD0=mongodb-0
MONGODB_POD1=mongodb-1
MONGODB_POD2=mongodb-2

#MLB_TMPL=./Infrastructure/templates/prod_setup_mlbparks_template.yaml
#NATIONAL_TMPL=./Infrastructure/templates/prod_setup_nationalparks_template.yaml
#PARKS_TMPL=./Infrastructure/templates/prod_setup_parksmap_template.yaml

echo ">>> STEP #1 > SET MONGODB REPLICAS"
oc create -f $MONGO_TMPL -n $PROJECT_NAME
sleep 15


echo ">>> LIVENESS CHECK FOR POD ${MONGODB_POD0} TO PROJECT ${PROJECT_NAME}"
sleep 20
while : ; do
  echo ">>> CHECK IF POD: ${MONGODB_POD0} IS ALIVE."
  oc get pod -n $PROJECT_NAME | grep $MONGODB_POD0 | grep -v build | grep -v deploy |grep "1/1.*Running"
  [[ "$?" == "1" ]] || break
  echo "<<< NOT YET :( >>>>> WAITING MORE 1O SECONDS AND TRY AGAIN."
  sleep 10
done

echo ">>> LIVENESS CHECK FOR POD ${MONGODB_POD1} TO PROJECT ${PROJECT_NAME}"
sleep 20
while : ; do
  echo ">>> CHECK IF POD: ${MONGODB_POD1} IS ALIVE."
 oc get pod -n $PROJECT_NAME | grep $MONGODB_POD1 | grep -v build | grep -v deploy |grep "1/1.*Running"
  [[ "$?" == "1" ]] || break
  echo "<<< NOT YET :( >>>>> WAITING MORE 1O SECONDS AND TRY AGAIN."
  sleep 10
done

echo ">>> LIVENESS CHECK FOR POD ${MONGODB_POD2} TO PROJECT ${PROJECT_NAME}"
sleep 20
while : ; do
  echo ">>> CHECK IF POD: ${MONGODB_POD2} IS ALIVE."
  oc get pod -n $PROJECT_NAME | grep $MONGODB_POD2 | grep -v build | grep -v deploy |grep "1/1.*Running"
  [[ "$?" == "1" ]] || break
  echo "<<< NOT YET :( >>>>> WAITING MORE 1O SECONDS AND TRY AGAIN."
  sleep 10
done




echo ">>> STEP #2 > SET APPS FOR PROD"

oc create -f $PARKSMAP_TMPL -n $PROJECT_NAME
sleep 10
oc create -f $NATIONALPARKS_TMPL -n $PROJECT_NAME
sleep 10
oc create -f $MLBPARKS_TMPL -n $PROJECT_NAME
sleep 10



echo ">>> STEP #3 > ADD VIEW PERMISSIONS"
oc policy add-role-to-group view system:serviceaccount:${GUID}-parks-prod -n ${GUID}-parks-dev
oc policy add-role-to-user view --serviceaccount=default -n $PROJECT_NAME

oc policy add-role-to-user view --serviceaccount=default -n $GUID-parks-prod
oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-prod

sleep 20