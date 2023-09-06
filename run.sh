#!/bin/env bash

# Get environment variables from .env 
source .env

# Set colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;94m'
NC='\033[0m' # No Color

check_env_vars() {
    # Set needed environment variables
    local env_vars=("SQLITE_DB_NAME" "DJANGO_SUPERUSER_USERNAME" "DJANGO_SUPERUSER_EMAIL" "DJANGO_SUPERUSER_PASSWORD" "DJANGO_PORT")

    # Check if needed environment variables are setted
    for var in "${env_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}$var is not set in the .env file${NC}"
            exit 1
        fi
    done
}

check_python_version() {
    # Check installed python version and set it to $python variable
    if [ -f $(command -v python3) ]; then
        python=$(command -v python3);
        installed_python_version=$($python -V | grep -oP '\d+\.\d+')
        true
    else
        echo -e "${RED}Python is not intalled on this system${NC}"
        false
    fi
}

get_package_manager() {
    # Get actual package manager and set it to $package_manager variable
    if command -v apt &>/dev/null; then
        package_manager="apt"

    elif command -v dnf &>/dev/null; then
        package_manager="dnf"

    elif command -v yum &>/dev/null; then
        package_manager="yum"
    
    # If package manager is not in list apt, yum, dnf print out message
    else
        if [ "$1" != "--no-install" ]; then  
            echo -e "${RED}Unsupported package manager${NC}"
            echo -e "Please resolve needed dependencies:"
            echo -e "\t- Python 3.9 and later"
            echo -e "\t- python3-pip"
            echo -e "\t- git"
            echo -e "\t- gcc"
            echo -e "\t- sed"
            echo -e "\t- libpq-dev"
            echo -e "\t- python-dev\n"
            echo -e "And then run this script with '--no-install' parameter"
            exit 1
        fi
    fi
}

update_cache() {

    # Update package manager packages cache
    if [ "$package_manager" == "apt" ]; then
        sudo $package_manager update
    elif [ "$package_manager" == "dnf" ] || [ "$package_manager" == "yum" ]; then
        sudo $package_manager check-update
    fi
}

set_packages() {
    # Breaking install command in pieces. 
    install_command="install"
    parameter="-y"

    # Set default packages' names depending to package manager 
    if [ "$package_manager" == "apt" ]; then        
        available_python_version=$(apt-cache madison python3 | grep -oP '\d+\.\d+' | head -n 1)
        devel_package="python${available_python_version}-dev"
        postgresql_lib=libpq-dev

    else
        available_python_version=$($package_manager list python3 | grep 'python3' | grep -oP '\d+\.\d+' | head -n 1)
        devel_package="python${available_python_version}-devel"
        postgresql_lib=postgresql-devel
    fi

    # Set version pf python installed on system
    installed_python_major_version=$(echo $installed_python_version | cut -d '.' -f 1)
    installed_python_minor_version=$(echo $installed_python_version | cut -d '.' -f 2)

    # Set version python available to install on system
    available_python_major_version=$(echo $available_python_version | cut -d '.' -f 1)
    available_python_minor_version=$(echo $available_python_version | cut -d '.' -f 2)

    # Form needed package list with correct names
    if [[ "$installed_python_major_version$installed_python_minor_version" -lt 39 ]]; then
        if [[ "$available_python_major_version$available_python_minor_version" -lt 39 ]]; then
            echo -e "${RED}Python 3.9 or later is required. Only Python $available_python_version is available in the repository. Please install Python 3.9 or later manually.${NC}"
            exit 1
        else
            common_packages=("python$available_python_version" "python3-pip" "git" "sed" "gcc" $postgresql_lib $devel_package)
        fi
    else
        common_packages=("python3-pip" "git" "sed" "gcc" $postgresql_lib $devel_package)
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
}

install_packages() {
    # Ask user if he wants to install additional packages
    if [ -n ${packages[*]} ]; then
        echo -e "Application needs some dependecies. They are: ${packages[*]}\nDo you want to install it?"
        while true; do
            read -p "Enter your choice (y/Y for 'yes' and n/N for 'no'): " choice
            case $choice in
                [Yy]* ) answer="YES"; break;;
                [Nn]* ) answer="NO"; break;;
                * ) echo "Please answer y/Y/n/N.";;
            esac
        done

        # If user agree
        if [ "$answer" == "YES" ]; then
            # If there are any packages to install, build the command and run it
            if [ ${#packages[@]} -gt 0 ]; then
                # Build the command as a single string
                full_command="sudo $package_manager $install_command $parameter ${packages[*]}"

                echo -e "${BLUE}Installing required packages: ${packages[*]}${NC}"
                eval $full_command

                # Check that the command completed successfully
                if [ $? -ne 0 ]; then
                    echo -e "${RED}Package installation failed. Please check the output above for more details.${NC}"
                    exit 1
                else
                    echo -e "${GREEN}All required packages installed successfully.${NC}"
                fi
            else
                echo -e "${GREEN}All required packages are already installed.${NC}"
            fi
        else
            exit 1
        fi

    else
        return
    fi
}

setup_virtualenv_and_repo() {

    # Get virtualenv module
    $python -m pip install virtualenv

    # Create virtual environment
    $python -m virtualenv -p $python venv

    # Activate virtual environment
    source venv/bin/activate

    # Get application over here 
    git clone https://github.com/manu-tgz/django-skyrim.git

    # Install needed dependencies
    cd django-skyrim/
    pip install -r requirements.txt
    pip install pytest-django

    # Create necessary tables in DB
    python manage.py makemigrations
    python manage.py migrate

    # Create django superuser
    DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD python manage.py createsuperuser --username $DJANGO_SUPERUSER_USERNAME --email $DJANGO_SUPERUSER_EMAIL --noinput

    # Automatic edit od settings.py to add DB parameters
    database_string="DATABASES"

    if [ $(grep -Fq $database_string config/settings.py; echo $?) -ne 0 ]; then 
	    echo -e "DATABASES = {\n    'default': {\n        'ENGINE': 'django.db.backends.sqlite3',\n        'NAME': BASE_DIR / '$SQLITE_DB_NAME',\n    }\n}" >> config/settings.py;
    fi

    # Create settings file for pytest	    
    echo -e "[pytest]\nDJANGO_SETTINGS_MODULE=config.settings" > pytest.ini

    # Some lightweight application fixes (author's fault)
    for file in $(grep -rnl -e 'test.copy.html' .); do
        sed -i 's/test copy.html/test.html/' $file
    done

    # Run tests
    pytest
}

run_django_server() {
    # Check if port is available on system
    if lsof -Pi :$DJANGO_PORT -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${RED}Port $DJANGO_PORT is already in use.${NC}"
        exit 1
    fi

    # Run application
    python manage.py runserver $DJANGO_PORT
}

main() {
    check_env_vars
    check_python_version
    get_package_manager $1

    if [ "$1" != "--no-install" ]; then
        update_cache
        set_packages
        install_packages
    fi

    setup_virtualenv_and_repo
    run_django_server
}

main $1
