#!/bin/env bash

source .env

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_env_vars() {
    local env_vars=("SQLITE_DB_NAME" "DJANGO_SUPERUSER_USERNAME" "DJANGO_SUPERUSER_EMAIL" "DJANGO_SUPERUSER_PASSWORD" "DJANGO_PORT")
    for var in "${env_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}$var is not set in the .env file${NC}"
            exit 1
        fi
    done
}

set_package_manager_and_packages() {
    python_version=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
    install_command="install"
    parameter="-y"

    if command -v apt &>/dev/null; then
        package_manager="apt"
        devel_package="python${python_version}-dev"
        psotgresql_lib=libpq-dev
    elif command -v dnf &>/dev/null; then
        package_manager="dnf"
        devel_package="python${python_version}-devel"
        psotgresql_lib=postgresql-devel
    elif command -v yum &>/dev/null; then
        package_manager="yum"
        devel_package="python${python_version}-devel"
        psotgresql_lib=postgresql-devel
    else
        echo -e "${RED}Unsupported package manager${NC}"
        exit 1
    fi

    common_packages=("python3-pip" "git" "sed" "gcc" $psotgresql_lib $devel_package)
}

install_packages() {
    # Update package list
    if [ "$package_manager" == "apt" ]; then
        sudo apt update
    elif [ "$package_manager" == "dnf" ]; then
        sudo dnf check-update
    elif [ "$package_manager" == "yum" ]; then
        sudo yum check-update
    fi

    # Initialize packages array
    packages=()

    # Check if each package is installed and add it to the packages array if not
    for package in "${common_packages[@]}"; do
        if [ "$package_manager" == "apt" ]; then
            if ! dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -q "ok installed"; then
                packages+=("$package")
            fi
        elif [ "$package_manager" == "dnf" ] || [ "$package_manager" == "yum" ]; then
            if ! rpm -q $package &>/dev/null; then
                packages+=("$package")
            fi
        fi
    done

    # If there are any packages to install, construct the command and run it
    if [ ${#packages[@]} -gt 0 ]; then
        # Construct the command as a single string
        full_command="sudo $package_manager $install_command $parameter ${packages[@]}"
        # Run the command
        echo -e "${BLUE}Installing packages...${NC}"
        eval $full_command
        echo -e "${GREEN}Installation completed.${NC}"
    else
        echo -e "${GREEN}All required packages are already installed.${NC}"
    fi
}

setup_virtualenv_and_repo() {
    pip install virtualenv
    python3 -m virtualenv venv
    source venv/bin/activate

    git clone https://github.com/manu-tgz/django-skyrim.git

    cd django-skyrim/

    pip install -r requirements.txt
    pip install pytest-django
    python3 manage.py makemigrations
    python3 manage.py migrate

    DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD python3 manage.py createsuperuser --username $DJANGO_SUPERUSER_USERNAME --email $DJANGO_SUPERUSER_EMAIL --noinput

    echo -e "DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3','NAME': BASE_DIR / '$SQLITE_DB_NAME',}}" >> config/settings.py

    echo -e "[pytest]\nDJANGO_SETTINGS_MODULE=config.settings" > pytest.ini

    for file in $(grep -rnl -e 'test.copy.html' .); do
        sed -i 's/test copy.html/test.html/' $file
    done

    pytest
}

run_django_server() {
    # Check if port is available
    if lsof -Pi :$DJANGO_PORT -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${RED}Port $DJANGO_PORT is already in use.${NC}"
        exit 1
    fi

    python3 manage.py runserver $DJANGO_PORT
}

main() {
    check_env_vars
    set_package_manager_and_packages
    install_packages
    setup_virtualenv_and_repo
    run_django_server
}

main
