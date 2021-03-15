# README #

This bash script can be use to setup local project using docker.

### Which operating systems are supported for this? ###

* Mac
* Linux

### Require installed programs ###

* docker
* docker-compose
* php (version as per project requirements)
* composer

### Which type of projects can be setup using this? ###

* Magento 2
* WordPress

### How to use this script? ###

Before runing this script

* make sure to keep "docker-compose.yaml.magento.sample" or "docker-compose.yaml.wordpress.sample" files along with this bash script in the same directory level.
* make sure docker and docker-compose are installed and running
* add project directory in docker > Preferences > Resources > FILE SHARING

Run: sh setup-project.sh

### How this script works ###

* This script will save your precious time to setup local Magento2 OR WordPress project using docker environment.
* Script will ask you couple of infomration to setup the project.
* Script will automatically add host entry on your OS host file for project to make it accessible on your local.
* This will also setup docker-compose.yml file for the project and run the containers.
* Script can automatically fetch and setup fresh Magento 2 project and install depedencies using composer.
* Script can automatically fetch and setup fresh WordPress project.
* Script will help you to import project's existing databse SQL file in mysql container.
* After setting up project using this script you will be able to manage Magento 2 or WordPress project as normal.
