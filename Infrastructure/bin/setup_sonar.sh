#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student
oc new-app -f ./Infrastructure/templates/sonarqube_template1.yaml\
  --param POSTGRESQL_USERNAME=sonar\
  --param POSTGRESQL_PASSWORD=sonar\
  --param POSTGRESQL_DATABASE=sonar\
  --param POSTGRESQL_VOLUME=4Gi\
  --param GUID=$GUID\
  -n $GUID-sonarqube

