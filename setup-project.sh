#!/bin/bash

#title           : setup-project.sh
#description     : This script will make a header for a bash script.
#company         : ELATEBRAIN PRIVATE LIMITED
#website         : https://www.elatebrain.com/
#author		     : Ankit Patel
#date            : 14 March 2021
#version         : 0.1    
#usage		     : bash mkscript.sh
#notes           : Install Docker, Docker-Compose, PHP and Composer to use this script. Require operating system: Mac OR Linux
#==============================================================================

#INPUT_COLOUR='\033[1;34'
#NO_COLOUR='\033[0m'

BASEDIR="$(basename "$PWD")";
PHP=`which php`;
COMPOSER=`which composer`;

directory_name=$(echo "$BASEDIR" | awk '{print tolower($0)}');
directory_name=$(echo "$BASEDIR" | sed -e 's/[^a-z^A-Z^0-9|^_]//g');

function detectOS() {
  unameOut="$(uname -s)"
  case "${unameOut}" in
      Linux*)     machine=Linux;;
      Darwin*)    machine=Mac;;
      *)          machine="UNKNOWN"
  esac
}

function getHostFilePath() {
  if [ "$machine" == "Mac" ]; then
    host_file_path="/private/etc/hosts";
  elif [ "$machine" == "Linux" ]; then
    host_file_path="/etc/hosts";
  elif [ "$machine" == "UNKNOWN" ]; then
    echo "Unable to detect operating system. Can not setup the project.";
    exit;
  else
    echo "Unable to detect operating system. Can not setup the project.";
    exit;
  fi
}

function checkDockerInstalled() {
  if [ ! -x "$(command -v docker)" ]; then
      echo "docker is not installed. Please install and run the script again.";
      exit;
  fi

  if [ ! -x "$(command -v docker-compose)" ]; then
      echo "docker-compose is not installed. Please install and run the script again.";
      exit;
  fi
}

function checkDockerComposeFileExist()
{
  if [[ -s docker-compose.yaml || -s docker-compose.yml ]]
  then
    return 1;
  else
    if [[ -s docker-compose.yaml.magento.sample || -s docker-compose.yaml.wordpress.sample ]]
    then
      ymlFilename="docker-compose.yaml";
      if [[ -s docker-compose.yaml.magento.sample ]]
      then
        cp docker-compose.yaml.magento.sample $ymlFilename;
      elif [[ -s docker-compose.yaml.wordpress.sample ]]
      then
        cp docker-compose.yaml.wordpress.sample $ymlFilename;
      fi
      sed -i '' -e "s/%SITE_DOMAIN%/$project_domain/g" $ymlFilename;
      sed -i '' -e "s/%DATABASE_NAME%/$database_name/g" $ymlFilename;
      sed -i '' -e "s/%PROJECT_NAME%/$project_name/g" $ymlFilename;
      sed -i '' -e "s/%MYSQL_ROOT_PASSWORD%/$mysql_root_password/g" $ymlFilename;
    else
      echo "docker-compose.yaml OR docker-compose.yml OR docker-compose.yaml.sample file not found. Exiting program";
      exit;
    fi
  fi
}

function startDockerContainers() {
  checkDockerComposeFileExist;
  docker-compose up -d;
}

function checkRequireDockerContainers() {
  if [ ! "$(docker container ls -q -f name=web)" ]; then
#      if [ ! "$(docker container ls -aq -f status=exited -f name=web)" ]; then
#          startDockerContainers;
#      fi
      startDockerContainers;
  fi

  if [ ! "$(docker container ls -q -f name=mysql)" ]; then
#      if [ ! "$(docker container ls -aq -f status=exited -f name=mysql)" ]; then
#          startDockerContainers;
#      fi
      startDockerContainers;
  fi
}

function addHostEntry() {
  matches_in_hosts="$(grep -n "${ip_address} ${project_domain}" $host_file_path | cut -f1 -d:)";
  host_entry="${ip_address} ${project_domain}";

  echo "Please enter your password if requested.";

  if [ -n "$matches_in_hosts" ]; then
      echo "Updating existing hosts entry.";
      while read -r line_number; do
          sudo sed -i '' "${line_number}s/.*/${host_entry} /" $host_file_path;
      done <<< "$matches_in_hosts";
  else
      echo "Adding new hosts entry.";
      echo "$host_entry" | sudo tee -a $host_file_path > /dev/null;
  fi
}

function installFreshMagento() {
  $PHP -d memory_limit=-1 $COMPOSER create-project --repository-url=https://repo.magento.com/ magento/project-community-edition ./tmp;
  shopt -s dotglob nullglob;
  mv ./tmp/* ./;
}

function installFreshWordPress() {
  curl -O https://wordpress.org/latest.tar.gz;
  tar -zxvf latest.tar.gz;
  cd ./wordpress;
  cp -rf . ..;
  cd ..;
  rm -R wordpress;

  cp wp-config-sample.php wp-config.php;
  perl -pi -e "s/database_name_here/$database_name/g" wp-config.php;
  perl -pi -e "s/username_here/root/g" wp-config.php;
  perl -pi -e "s/password_here/$mysql_root_password/g" wp-config.php;
  perl -pi -e "s/localhost/mysql/g" wp-config.php;

  perl -i -pe'
    BEGIN {
      @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
      push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
      sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
  ' wp-config.php

  mkdir wp-content/uploads;
  chmod 775 wp-content/uploads;
  rm latest.tar.gz;
}

detectOS;
getHostFilePath;

read -p "Enter project name [$directory_name]: " project_name;
if [ -z "$project_name" ]; then
  project_name=$directory_name;
fi

project_name=$(echo "$project_name" | awk '{print tolower($0)}');
project_name=$(echo "$project_name" | sed -e 's/[^a-z^A-Z^0-9|^_]//g');
echo "Project Name: $project_name";

echo "Setting up project on ${machine} operating system...";

read -p "Enter project domain (without http:// or https://): " project_domain;
if [ -z "$project_domain" ]; then
  echo "Can not setup project without project domain.";
  exit;
fi
project_domain=$(echo "$project_domain" | sed -e 's|^[^/]*//||' -e 's|/.*$||');
echo "Project Domain: $project_domain";

read -p "Enter project ip [127.0.0.1]: " projectip;
if [[ $projectip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  ip_address="${projectip}";
else
  ip_address="127.0.0.1";
fi
echo "Project IP: $ip_address";

addHostEntry;

read -p "Enter database name [$project_name]: " database_name;
if [ -z "$database_name" ]; then
  database_name=$project_name;
fi

database_name=$(echo "$database_name" | awk '{print tolower($0)}');
database_name=$(echo "$database_name" | sed -e 's/[^a-z^A-Z^0-9|_]//g');
echo "Database Name: $database_name";

read -p "Enter mysql root user password [root]: " mysql_root_password;
if [ -z "$mysql_root_password" ]; then
  mysql_root_password="root";
fi

echo "MYSQL Root user password: $mysql_root_password";

checkDockerInstalled;
checkRequireDockerContainers;

platform="";
PS3="Choose project platform: ";
options=("magento2" "wordpress" "Quit");
select opt in "${options[@]}"
do
    case $opt in
        "Quit")
          echo "End of program!";
          exit;
          ;;
        *)
          platform=$opt;
          break;
          ;;
    esac
done

if [ "$platform" == "magento2" ]
then
  PS3="Install fresh Magento2?: ";
  select yn in "Yes" "No";
  do
    case $yn in
      Yes )
        installFreshMagento;
        break
        ;;
      No )

        break
        ;;
    esac
  done
elif [ "$platform" == "wordpress" ]
then
  PS3="Install fresh WordPress?: ";
  select yn in "Yes" "No";
  do
    case $yn in
      Yes )
        installFreshWordPress;
        break
        ;;
      No )

        break
        ;;
    esac
  done
fi

read -p "Enter SQL file path to import into database '$database_name' [Leave blank to skip import]: " sql_file_path;
if [ -z "$sql_file_path" ]; then
  echo "Skipping database import...";
else
  if [[ -s "$sql_file_path" ]]
  then
    docker container exec -i mysql mysql --init-command="SET SESSION FOREIGN_KEY_CHECKS=0; SET SESSION sql_mode='NO_AUTO_VALUE_ON_ZERO';" -h 127.0.0.1 -u root -p$mysql_root_password $database_name < "$sql_file_path";
  fi
fi

echo "Project has been setup successfully.";
if [ "$platform" == "magento2" ]
then
  echo "You can now continue installing OR using magento.";
else
  echo "You can now continue installing OR using wordpress.";
fi

exit;
