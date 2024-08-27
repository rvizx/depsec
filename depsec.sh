#!/bin/bash


#  Title    : DepSec - Automated Software Dependency Security Analysis Tool 
#  Author   : Ravindu Wickramasinghe | rvz (@rvizx9) | rviz@pm.me 
#  Project  : https://github.com/rvizx/depsec


# Note : This project is completely based on the `DependencyCheck` project and `depsec` is a simple wrapper over the `DependencyCheck` application to automate it's process and  it also include some additional features. 
# Link : https://github.com/jeremylong/DependencyCheck



# ---------------------------------------------------------------

# directory of the script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# source the .env file if it exists
[ -f "$SCRIPT_DIR/.env" ] && export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)


nvdApiKey="${NVD_API_KEY}"
recipient="${DEPSEC_RECIPIENT}"
project_dir="${DEPSEC_PROJECT}"





# find and install npm packages in directories with package.json before executing the dependency-check
npm_install() {
    if [ ! -d "$project_dir" ]; then
        echo "[depsec] error: directory $project_dir does not exist."
        exit 1
    fi

    find "$project_dir" -type d -name 'node_modules' -prune -o -type f -name 'package.json' -print | while read -r pkg_file; do
        pkg_dir=$(dirname "$pkg_file")
        echo "[depsec] running 'npm install' in $pkg_dir"
        (cd "$pkg_dir" && npm install)
    done
}


# same as  above, but using yarn
yarn_install() {
    if [ ! -d "$project_dir" ]; then
        echo "[depsec] error: directory $project_dir does not exist."
        exit 1
    fi

    find "$project_dir" -type d -name 'node_modules' -prune -o -type f -name 'package.json' -print | while read -r pkg_file; do
        pkg_dir=$(dirname "$pkg_file")
        echo "[depsec] running 'yarn install --refresh-lockfile' in $pkg_dir"
        (cd "$pkg_dir" && yarn install --refresh-lockfile)
    done
}

# same as above, but using composer for composer dependencies
composer_install() {
    if [ ! -d "$project_dir" ]; then
        echo "[depsec] error: directory $project_dir does not exist."
        exit 1
    fi

    find "$project_dir" -type d -name 'node_modules' -prune -o -type f -name 'package.json' -print | while read -r pkg_file; do
        pkg_dir=$(dirname "$pkg_file")
        echo "[depsec] running 'composer install --no-interaction --prefer-dist' in $pkg_dir"
        (cd "$pkg_dir" && composer install --no-interaction --prefer-dist)
    done
}


send_email() {
  boundary=$(date +%s | md5sum | awk '{print $1}')
  mailtrap_user="${MAILTRAP_USER}"
  encoded_file=$(base64 /tmp/depsec-report.zip)
  
  EMAIL_CONTENT=$(cat <<EOF
From: DepSec Automation <mailtrap@demomailtrap.com>
To: Mailtrap Inbox <$recipient>
Subject: DEPSEC Report - $(date)
Content-Type: multipart/mixed; boundary="$boundary"

--$boundary
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit

Congrats for sending test email with Mailtrap!

--$boundary
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 7bit

--$boundary
Content-Type: application/zip
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="depsec-report.zip"

$encoded_file

--$boundary--
EOF
)

  echo "$EMAIL_CONTENT" | curl -vvv \
    --ssl-reqd \
    --url 'smtp://live.smtp.mailtrap.io:587' \
    --user "$mailtrap_user" \
    --mail-from mailtrap@demomailtrap.com \
    --mail-rcpt "$recipient" \
    --upload-file -
}


# depcheck main scan command
depcheck_scan(){
    ~/.local/share/dependency-check/bin/./dependency-check.sh --out /tmp/depsec-report.html --scan "$project_dir" --nvdApiKey "$nvdApiKey" 
    cd /tmp && zip -r depsec-report.zip depsec-report.html
}





# install pre-requisites - for debian based
install_prerequisites() {
    if [[ -f /etc/debian_version ]]; then
        echo "[depsec] detected debian-based os. installing packages..."
        sudo apt-get update -y
        sudo apt-get install -y git wget unzip curl maven nodejs npm
        
        echo "[depsec] installation of common packages complete!"

        echo "[depsec] installing composer..."
        curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

        echo "[depsec] installing yarn..."
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        sudo apt-get update -y
        sudo apt-get install -y yarn
        
        echo "[depsec] all installations complete!"

    else
        echo "[depsec] unsupported os. this script supports only debian-based distributions."
        return 1
    fi
}




# function to find the latest dependency check release, download and setup it 
install_dependency_check() {
    echo "[depsec] finding the latest dependencycheck version..."
    lv=$(curl -s https://github.com/jeremylong/DependencyCheck/releases/ | grep href | grep releases | grep span | head -n 1 | cut -d "\"" -f 6 | cut -d "/" -f 6)
    echo "[depsec] latest version : $lv"
    endpoint=$(curl -sL "https://github.com/jeremylong/DependencyCheck/releases/expanded_assets/$lv" | grep .zip | grep href | head -n 1 | cut -d "\"" -f 2)
    wget "https://github.com${endpoint}" -O ~/.local/share/depcheck.zip
    cd ~/.local/share/ 
    unzip depcheck.zip
    chmod +x ~/.local/share/dependency-check/bin/dependency-check.sh
    echo "[depsec] installation complete!"
}





# function to update to the latest dependency check release, download and setup it 
update_dependency_check() {
    sudo rm -rf  ~./local/share/dependency-check
    echo "[depsec] finding the latest dependencycheck version..."
    lv=$(curl -s https://github.com/jeremylong/DependencyCheck/releases/ | grep href | grep releases | grep span | head -n 1 | cut -d "\"" -f 6 | cut -d "/" -f 6)
    echo "[depsec] latest version : $lv"
    endpoint=$(curl -sL "https://github.com/jeremylong/DependencyCheck/releases/expanded_assets/$lv" | grep .zip | grep href | head -n 1 | cut -d "\"" -f 2)
    wget "https://github.com${endpoint}" -O ~/.local/share/depcheck.zip
    cd ~/.local/share/ 
    unzip depcheck.zip
    chmod +x ~/.local/share/dependency-check/bin/dependency-check.sh
    echo "[depsec] update process is complete!"
}




# function to configure the email configurations and the nvd-api-key 
configure() {
    read -p "[depsec] enter the nvd api key (https://nvd.nist.gov/developers/request-an-api-key): " nvdapikey
    read -p "[depsec] enter the recipient email address: " recipient
    read -p "[depsec] enter project directory: " project_dir
    read -p "[depsec] enter mailtrap user: " mailtrap_user
    echo

    echo "NVD_API_KEY=\"$nvdapikey\"" >> .env
    echo "DEPSEC_RECIPIENT=\"$recipient\"" >> .env
    echo "DEPSEC_PROJECT=\"$project_dir\"" >> .env
    echo "MAILTRAP_USER=\"$mailtrap_user\"" >> .env

    echo "[depsec] nvd api key has been set as an environment variable."
    echo "[depsec] mailtrap configuration has been set up in "
    exit
}




# depsec uninstallation script
uninstall() {
    rm -rf ~/.local/share/dependency-check
    rm -rf "$SCRIPT_DIR"
}

# depsec - main script and functionality
case "$1" in
    --scan)
        npm_install
        yarn_install
        composer_install
        depcheck_scan
        send_email
        ;;
    
    --install)
        install_prerequisites
        install_dependency_check
        ;;
    
    --update)
        update_dependency_check
        ;;

    --config)
        configure
        ;;
    
    --uninstall)
        uninstall
        ;;
    *)
        echo "[depsec]  usage: $0  --install | --scan | --update | --config | --uninstall"
        exit 1
        ;;
esac
