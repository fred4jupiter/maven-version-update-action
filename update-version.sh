#!/bin/bash

for i in "$@"
do
case $i in
    -gu=*|--github-username=*)
    GITHUB_USERNAME="${i#*=}"
    ;;
    -gp=*|--github-password=*)
    GITHUB_PASSWORD="${i#*=}"
    ;;
    -ge=*|--github-email=*)
    GITHUB_EMAIL="${i#*=}"
    ;;
esac
done

if [ $# -eq 0 ]; then
    echo "No arguments provided. Usage example: ./update-version.sh -gu=freddy -gp='secret'"
    exit 1
fi

if [ -z "$GITHUB_USERNAME" ]
  then
    echo "Please define the Github username. Example: -gu=freddy"
    exit 1
fi

if [ -z "$GITHUB_PASSWORD" ]
  then
    echo "Please define the Github password. Example: -gp=secret"
    exit 1
fi

if [ -z "$GITHUB_EMAIL" ]
  then
    echo "Please define the Github email address. Example: -ge=something@somewhere.com"
    exit 1
fi

git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL

REPO="scm:git:https://$GITHUB_ACTOR:$GITHUB_PASSWORD@github.com/$GITHUB_REPOSITORY.git"

mvn build-helper:parse-version versions:set -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion} versions:commit -DconnectionUrl=$REPO
mvn build-helper:parse-version scm:tag -Dbasedir=. -Dtag=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion} -Dusername=$GITHUB_USERNAME -Dpassword=$GITHUB_PASSWORD -DconnectionUrl=$REPO
PROJECT_REL_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)

mvn build-helper:parse-version versions:set -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion}-SNAPSHOT versions:commit -DconnectionUrl=$REPO
NEXT_DEV_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)

git commit -a -m "next dev version $NEXT_DEV_VERSION"
git push

echo "release version is: $PROJECT_REL_VERSION"
echo "next development version is: $NEXT_DEV_VERSION"

echo $PROJECT_REL_VERSION > release_version.txt
echo $NEXT_DEV_VERSION > next_dev_version.txt
