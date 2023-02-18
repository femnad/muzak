#!/usr/bin/env bash
set -euEo pipefail

function muzak_up() {
    if ! ssh-add -l > /dev/null 2>&1
    then
        ssh-add $HOME/.ssh/$(hostname -s)
    fi

    root_dir=$(dirname $(realpath $0))
    pushd "${root_dir}/terraform"

    if ! [ -d .terraform/ ]
    then
        make
    fi

    current_ssid=$(nmcli --terse -f SSID,ACTIVE device wifi | grep -E ':yes$' | awk -F ':' '{print $1}')
    managed_ssid=$(pass meta/managed-connection/ssid)
    managed_connection=false

    if [ "$managed_ssid" = "$current_ssid" ]
    then
        managed_connection=true
    fi

    terraform apply -auto-approve -var "managed_connection=$managed_connection"
    popd

    pushd "${root_dir}/ansible"
    export -n ANSIBLE_CONFIG
    ansible-playbook muzak.yml
    popd
}

function muzak_down() {
    root_dir=$(dirname $(realpath $0))
    pushd "${root_dir}/terraform"

    terraform destroy -auto-approve
    popd
}

function main() {
    if [ $# -ne 1 ]
    then
        echo "usage: $(basename $(realpath $0)) <up|down>"
        exit 1
    fi

    subcommand="$1"
    case $subcommand in
        up)
            shift
            muzak_up $@
            ;;
        down)
            shift
            muzak_down $@
            ;;
        *)
            echo "Unrecognized subcommand ${subcommand}"
            exit 1
            ;;
    esac
}

main $@
