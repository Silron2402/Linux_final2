#!/usr/bin/env bash

#Проверим права суперпользователя
if [ "$(id -u)" != "0" ]; then
    echo "Необходимо запустить скрипт от имени root или c sudo"
    exit 1
fi

#Выполним установку и настройку системной локали
echo "Добавление в sources.list-директорию файл с сервером, где хранятся пакеты для ROS1..."
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

#Выполним установку и настройку curl
echo "Установка curl..."
apt install curl

#Добавление репозитория ROS1
echo "Добавление репозитория ROS1..."
curl -s 
https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

#Установка ROS1
echo "Установка ROS1 full версии..."
apt update
apt install ros-noetic-desktop-full

#Настройка окружения
echo "Настройка окружения ROS1..."
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
#source ~/.bashrc

echo "Установка дополнительных инструментов..."
sudo apt install -y \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool duild-essential \
    

echo "Инициализация rosdep.."
sudo apt install python3-rosdep
sudo rosdep init
rosdep update

#Обновление существующего терминала
source ~/.bashrc
echo "Установка ROS1 завершена успешно!"

