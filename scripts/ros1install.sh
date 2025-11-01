#!/usr/bin/env bash

#команды настройки выполнения скрипта
#прерывать скрипт при любой ошибке;
#сообщение об ошибке при обнаружении неопределенных переменных
#настройка пайпа возвращать код ошибки первой упавшей команды.
set -eu -o pipefail

# Обработка прерывания скриптом (Ctrl+C)
trap 'log_msg "Скрипт прерван пользователем"; exit 1' INT

#логирование с датой для отладки
log_msg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Функция проверки установленного пакета
is_package_installed() {
    local package="$1"
    dpkg -s "$package" &>/dev/null
}

#Установка версии ROS и параметров системной локали
ROS_DISTRO="noetic"
#установка и экспорт переменной окружения LANG c базовыми настройками 
#для текущей сессии терминала и запускаемых в ней программ
LOCALE="en_US.UTF-8"

#списки устанавливаемых пакетов
required_packages1=(
    "curl"           # Загрузка файлов
    "gnupg"          # Работа с GPG‑ключами
    "lsb-release"    # Определение версии дистрибутива
)

required_packages2=(
    "python3-rosdep"                # Управление зависимостями ROS
    "python3-rosinstall"            # Работа с репозиториями ROS
    "python3-rosinstall-generator"  # Генерация списков репозиториев
    "python3-wstool"                # Управление рабочими пространствами
    "build-essential"               # Компиляторы и инструменты сборки
)

#Получение имени пользователя и адреса домашнего каталога
USERNAME=$(whoami)
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)

#проверка интернет-соединения
if ! ping -c 1 github.com &> /dev/null; then
    log_msg "Отсутсвует интернет‑соединение!"
    exit 1
fi

#Проверка прав суперпользователя
if [ "$(id -u)" != "0" ]; then
    log_msg "Необходимо запустить скрипт от имени root или c sudo"
    exit 1
fi

# Установка и настройка локали
log_msg "Настройка системной локали..."
apt-get update
apt-get install -y locales
locale-gen "$LOCALE"
update-locale LC_ALL="$LOCALE" LANG="$LOCALE"
export LANG="$LOCALE" LC_ALL="$LOCALE"

#Выполним установку и настройку базовых пакетов
log_msg "Установка базовых пакетов..."
for pkg in "${required_packages1[@]}"; do
    if ! is_package_installed "$pkg"; then
        log_msg "Пакет $pkg не установлен. Устанавливаем..."
        apt-get install -y "$pkg"
    else
        log_msg "Пакет $pkg уже установлен"
    fi
done

# Добавление репозитория ROS1
log_msg "Добавление репозитория ROS1..."
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
#log_msg "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list

if ! curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -; then
    log_msg "Ошибка: не удалось добавить GPG‑ключ ROS"
    exit 1
fi

# Обновление списка пакетов
log_msg "Обновление списка пакетов"
apt-get update

#Установка ROS1
if is_package_installed "ros-$ROS_DISTRO-desktop-full"; then
    log_msg "Пакет ROS1 уже установлен"
else
    echo "Установка ROS1 full версии..."
    #установка
    apt-get install -y "ros-$ROS_DISTRO-desktop-full"
fi

#Настройка окружения
log_msg "Настройка окружения ROS1..."

# Определяем путь к setup.bash
ROS_SETUP="/opt/ros/$ROS_DISTRO/setup.bash"

# Проверяем существование файла
if [ ! -f "$ROS_SETUP" ]; then
    log_msg "Ошибка: файл $ROS_SETUP не найден!"
    exit 1
fi

# Проверяем существование файла
if [ ! -f "~/.bashrc" ]; then
    log_msg "Ошибка: файл ~/.bashrc не найден!"
    exit 1
fi

# Добавляем в .bashrc (для текущего пользователя)
echo "source $ROS_SETUP" >> ~/.bashrc
log_msg "Строка 'source $ROS_SETUP' добавлена в ~/.bashrc"

# Применяем настройки в текущем окружении
source "$ROS_SETUP"
log_msg "Окружение ROS1 настроено успешно!"




#echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> "$USER_HOME/.bashrc"
#№su -c 'echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> $USER_HOME/.bashrc' 
#source /opt/ros/"$ROS_DISTRO"/setup.bash

#Установка и настройка дополнительных инструментов
log_msg "Установка дополнительных инструментов..."
for pkg in "${required_packages2[@]}"; do
    if ! is_package_installed "$pkg"; then
        log_msg "Пакет $pkg не установлен. Устанавливаем..."
        apt-get install -y "$pkg"
    else
        log_msg "Пакет $pkg уже установлен"
    fi
done

#инициализация rosdep
log_msg "Инициализация rosdep.."
if ! rosdep init; then
    log_msg "Ошибка: rosdep init failed"
    exit 1
fi
rosdep update

#Финальное сообщение
log_msg "Установка ROS1 завершена успешно!"

