# Bash Script for Setting up a Django Application
This is a Bash script that automates the process of setting up a Django application. It performs various tasks such as checking if required environment variables are set, installing necessary packages, setting up a virtual environment, cloning a git repository, running migrations, creating a Django superuser, and running the Django development server.

## Script Overview
The script is divided into functions, each responsible for a specific task. Here are the functions and what they do:

* **`check_env_vars`**: Checks if the required environment variables are set. If not, the script exits with an error message.
* **`set_package_manager_and_packages`**: Determines the package manager (`apt`, `dnf`, or `yum`) of the system and sets the package installation command and necessary packages.
* **`install_packages`**: Checks if the necessary packages are already installed. If not, installs them using the package manager determined earlier.
* **`setup_virtualenv_and_repo`**: Sets up a virtual environment, clones the Django application repository from GitHub, installs the required Python packages from requirements.txt, runs Django migrations, and creates a Django superuser.
* **`run_django_server`**: Checks if the specified port is available and runs the Django development server on that port.
* **`main`**: The main function that calls all the other functions in order.

## Prerequisites
* Python 3
* Bash shell
* Git

The following environment variables must be set in a **.env** file located in the same directory as the script:
* **`SQLITE_DB_NAME`**: The name of the SQLite database file.
* **`DJANGO_SUPERUSER_USERNAME`**: The username of the Django superuser to be created.
* **`DJANGO_SUPERUSER_EMAIL`**: The email of the Django superuser.
* **`DJANGO_SUPERUSER_PASSWORD`**: The password of the Django superuser.
* **`DJANGO_PORT`**: The port on which the Django development server will run.

## Usage
1. Clone this repository or copy the script to your local machine.
2. Make the script executable by running **chmod +x script_name.sh**.
3. Create a `.env` file in the same directory as the script and set the required environment variables as mentioned in the **Prerequisites section**.
4. Run the script using **./script_name.sh**.

## Script Details
**`check_env_vars`** Function
This function checks if all the required environment variables (`SQLITE_DB_NAME`, `DJANGO_SUPERUSER_USERNAME`, `DJANGO_SUPERUSER_EMAIL`, `DJANGO_SUPERUSER_PASSWORD`, `DJANGO_PORT`) are set in the `.env` file. If any of them is not set, the script exits with an error message.

**`set_package_manager_and_packages`** Function
This function determines the package manager of the system (`apt`, `dnf`, or `yum`) and sets the package installation command, parameter, and necessary packages accordingly.

**`install_packages`** Function
This function checks if the necessary packages (`python3-pip`, `git`, `sed`, `libpq-dev(portgresql-devel)`, `python<version>-dev(devel)`) are already installed. If not, installs them using the package manager determined earlier.

**`setup_virtualenv_and_repo`** Function
This function sets up a virtual environment, clones the Django application repository from GitHub, installs the required Python packages from requirements.txt, runs Django migrations, creates a Django superuser, modifies the config/settings.py file to set the database configuration, creates a pytest.ini file, modifies HTML file names in the repository, and runs the pytest test suite.

**`run_django_server`** Function
This function checks if the specified port is available. If not, exits with an error message. Otherwise, runs the Django development server on that port.

**`main Function`**
The main function calls all the other functions in order. This is the function that gets executed when the script is run.

## Conclusion
This script simplifies the process of setting up a Django application by automating various tasks such as environment variable checks, package installations, virtual environment setup, repository cloning, migrations, superuser creation, and running the development server. Make sure to have the prerequisites installed and the required environment variables set in a `.env` file before running the script.