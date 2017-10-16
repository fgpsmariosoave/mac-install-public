#!/bin/bash
download_folder="/Users/Shared/_Launchmetrics"

if [[ -z ${2+x} ]] ; then
    echo "You need to specify the url of the package for downloading."
    exit 1
fi

app_name="$1"
app_dl_folder="${1%%.app}"

download_url="$2"
download_filename="${2##*/}"

checksum_needed=true

if [[ -z ${3+x} ]] ; then
    echo "WARNING: Checksum not specified, so will not be verified."
    checksum_needed=false
fi

app_checksum="$3"



check_if_installed()
{
    echo "Checking if $app_name is installed."

    if [[ -d "/Applications/${app_name}" ]] ; then
        return 1
    elif [[ -d "/Users/$(whoami)/Applications/${app_name}" ]] ; then
        return 1
    else
        return 0
    fi
}

download_package()
{
    echo "Downloading package for $app_name."
    mkdir -p "${download_folder}/${app_dl_folder}/"
    set +x
    curl -L "$download_url" -o "${download_folder}/${app_dl_folder}/${download_filename}"
}

verify_package_checksum()
{
    echo "Verifying checksum of package for ${app_name}."
    current_checksum=$(shasum -a 256 "${download_folder}/${app_dl_folder}/${download_filename}")
    current_checksum=${current_checksum%% *}

    if [[ "$app_checksum" == "$current_checksum" ]] ; then
        return 0
      else
        return 1
    fi
}

install_package()
{
    file_ext="${download_filename##*.}"
    if [[ $file_ext == "dmg" ]]  ; then
        #set -x
        attach_info="$(yes qy | hdiutil attach "${download_folder}/${app_dl_folder}/${download_filename}" | tail -n 1)"
        #set +x
        echo "Attach info: $attach_info"
        device_path="${attach_info%% *}"
        mount_path="/Volumes/${attach_info##*/Volumes/}"

        echo "Checking if $app_name is installed."
        # This will popuate the app_name variable.

        echo "Copying app to application directory"
        cp -pPR "${mount_path}/${app_name}" "/Applications/${app_name}"

        hdiutil detach $device_path

    elif [[ $file_ext = "pkg" ]] ; then
        echo "Installing .pkg file."
        installer -pkg "${download_folder}/${app_dl_folder}/${download_filename}" -target /
    else
        echo "We don't know how to install files with extention .$file_ext"
    fi
}

# Finally we have the overarching logic of installing a package.
# Should be easy to understand.

if check_if_installed ; then
    download_package

    if [[ $checksum_needed == false ]] ; then
        install_package
    elif verify_package_checksum ; then
        echo "Checksum verified."
        install_package
    else
        echo "Checksum_ needed = $checksum_needed"
        echo "Package checksum for $app_name could not be verified. Aborting install."
    fi
else
    echo "Package for $app_name is already installed. Aborting install."
fi

# TODO: Don't redownload file if a downloaded checksum verified copy already exists.
