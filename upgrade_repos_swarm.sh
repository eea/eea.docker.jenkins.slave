#!/bin/sh

git pull

wget -O index.html https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/
new_version=$(cat index.html | awk -F'\>|\/' '{print $3}' | sort -n | tail -n 1)
rm index.html

echo "New version is $new_version"
echo "Continue? enter for yes, anything else for no"
read check
if [ -n "$check" ]; then
 echo "Give new version"
 read new_version
fi

new_tag=$new_version
echo "New tag is $new_tag"
echo "Continue? enter for yes, anything else for no"
read check
if [ -n "$check" ]; then
 echo "Give new tag"
 read new_tag
fi


wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$new_version/swarm-client-$new_version.jar
new_md5=$(md5sum swarm-client-$new_version.jar| awk '{print $1}')
rm swarm-client-$new_version.jar

sed -i "s#SWARM_VERSION=.* #SWARM_VERSION=$new_version #" Dockerfile
sed -i "s#MD5=.* #MD5=$new_md5 #" Dockerfile

if [ $(grep -c $new_tag/Dockerfile Readme.md) -eq 0 ]; then
sed -i "s|.*eea.docker.jenkins.slave/blob/[0-9].*|\- [\`:$new_tag\` (*Dockerfile*)](https://github.com/eea/eea.docker.jenkins.slave/blob/$new_tag/Dockerfile)|" Readme.md  
fi



if [ $(grep -c "## $new_tag " CHANGELOG.md) -eq 0 ]; then

block="## $new_tag ($(date +%F))\n\n- Upgrade to swarm-client $new_version\n"
echo $block 
echo "Continue? enter for yes, anything else for no"
read check
if [ -n "$check" ]; then
 echo "Give new changelog"
 read block
fi
sed -i "3 i $block" CHANGELOG.md
fi

git diff | more
git status
if [ $( git diff | wc -l ) -ne 0 ]; then
 echo "continue? git commit"
 read check
 if [ -z "$check" ]; then
  git add Dockerfile CHANGELOG.md Readme.md
  git commit -m "Upgrade to swarm-client $new_version"
  git push
 fi
fi

if [ $( git tag | grep -c $new_tag ) -eq 0 ]; then

 echo "continue? git tag"
 read check
 if [ -z "$check" ]; then
  git tag -a $new_tag -m $new_tag
  git push origin $new_tag
 fi
fi


echo "upgrade slave-eea"
echo "continue?"
read check
if [ -z "$check" ]; then

#upgrade slave-eea
cd ../eea.docker.jenkins.slave-eea/

git pull
sed -i "s/jenkins-slave:.*/jenkins-slave:$new_tag/" Dockerfile

if [ $(grep -c $new_tag/Dockerfile Readme.md) -eq 0 ]; then
sed -i "s|.*eea.docker.jenkins.slave/blob/[0-9].*|\- [\`:$new_tag\` (*Dockerfile*)](https://github.com/eea/eea.docker.jenkins.slave/blob/$new_tag/Dockerfile)|" Readme.md
fi

if [ $(grep -c "## $new_tag " CHANGELOG.md) -eq 0 ]; then
block="## $new_tag ($(date +%F))\n\n- Upgrade to swarm-client $new_version\n"
echo $block 
echo "Continue? enter for yes, anything else for no"
read check
if [ -n "$check" ]; then
 echo "Give new changelog"
 read block
fi
sed -i "3 i $block" CHANGELOG.md
fi

git diff | more
git status
if [ $( git diff | wc -l ) -ne 0 ]; then
 echo "continue? git commit"
 read check
 if [ -z "$check" ]; then
  git add Dockerfile CHANGELOG.md Readme.md
  git commit -m "Upgrade to swarm-client $new_version"
  git push
 fi
fi

if [ $( git tag | grep -c $new_tag ) -eq 0 ]; then
 echo "continue? git tag"
 read check
 if [ -z "$check" ]; then
  git tag -a $new_tag -m $new_tag
  git push origin $new_tag
 fi
fi

fi


echo "upgrade slave-dind"
echo "continue?"
read check
if [ -z "$check" ]; then

#upgrade slave-dind
cd ../eea.docker.jenkins.slave-dind/

git pull
sed -i "s/jenkins-slave:.*/jenkins-slave:$new_tag/" Dockerfile

block="\n\n- Upgrade to swarm-client $new_version\n"


echo "Check docker engine version - https://docs.docker.com/engine/release-notes/"

docker_version=$(grep DOCKER_VERSION= Dockerfile | awk -F'=| ' '{print $3}')

echo "Current version is $docker_version, write new version if you want to upgrade"
read text
if [ -n "$text" ]; then
echo "New version is $text, continue?"
read check
if [ -z "$check" ]; then
  docker_version=$text
  sed -i "s/DOCKER_VERSION=.* /DOCKER_VERSION=$docker_version /" Dockerfile
  block=$block"- Upgrade to docker $docker_version\n"
fi  
fi

echo "Check docker compose version - https://docs.docker.com/compose/release-notes/"

docker_compose_version=$(grep DOCKER_COMPOSE_VERSION= Dockerfile | awk -F= '{print $2}' | awk '{print $1}' )
echo "Current version is $docker_compose_version, write new version if you want to upgrade"
read text
if [ -n "$text" ]; then
echo "New version is $text, continue?"
read check
if [ -z "$check" ]; then
  docker_compose_version=$text
  sed -i "s/DOCKER_COMPOSE_VERSION=.* /DOCKER_COMPOSE_VERSION=$docker_compose_version /" Dockerfile
  curl -o docker-compose -SL https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-Linux-x86_64
  new_md5=$(md5sum docker-compose | awk '{print $1}')
  rm docker-compose
  sed -i "s/DOCKER_COMPOSE_MD5=.* /DOCKER_COMPOSE_MD5=$new_md5 /" Dockerfile

  block=$block"- Upgrade to docker-compose $docker_compose_version\n"
fi
fi 


new_dind_tag=$(echo $docker_version | awk -F':|\.' '{print $2"."$3}')"-"$new_tag

echo "New tag is $new_dind_tag"
echo "Continue? enter for yes, anything else for no"
read check
if [ -n "$check" ]; then
 echo "Give new tag"
 read new_dind_tag
fi

new_tag=$new_dind_tag

block="## $new_tag ($(date +%F))$block"


if [ $(grep -c $new_tag/Dockerfile Readme.md) -eq 0 ]; then
sed -i "s|.*eea.docker.jenkins.slave/blob/[0-9].*|\- [\`:$new_tag\` (*Dockerfile*)](https://github.com/eea/eea.docker.jenkins.slave/blob/$new_tag/Dockerfile)|" Readme.md
fi

if [ $(grep -c "## $new_tag " CHANGELOG.md) -eq 0 ]; then
echo $block 
echo "Continue? enter for yes, anything else for no"
read check
if [ -n "$check" ]; then
 echo "Give new changelog"
 read block
fi
sed -i "3 i $block" CHANGELOG.md
fi

git diff | more
git status
if [ $( git diff | wc -l ) -ne 0 ]; then
 echo "continue? git commit"
 read check
 if [ -z "$check" ]; then
  git add Dockerfile CHANGELOG.md Readme.md
  git commit -m "Upgrade to $new_tag"
  git push
 fi
fi

if [ $( git tag | grep -c $new_tag ) -eq 0 ]; then
 echo "continue? git tag"
 read check
 if [ -z "$check" ]; then
  git tag -a $new_tag -m $new_tag
  git push origin $new_tag
 fi
fi

fi




