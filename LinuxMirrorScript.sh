#!/bin/env bash
#
# Written by: Robin Gierse - info@thorian93.de - on 20180328
#
# Purpose:
# This script mirrors several remote repositories to a mirror server.
#
# Version: 1.0 on 20180328 - Initial commit. Script is productive.
# Version: 1.1 on 20180507 - Update Script with third party repository of iuscommunity.org
# Version: 1.2 on 20181006 - Update script with some improvements
# Version: 1.3 on 20181202 - Add debmirror abilities for debian
# Version: 1.4 on 20181217 - Add debmirror abilities for ubuntu
# Version: 1.5 on 20181230 - Add torproject repository - still testing
# Version: 2.0 on 20190102 - Add Ubuntu Bionic release
# Version: 2.1 on 20190109 - Tweak formatting and structure and update with some stuff - testing necessary
# Version: 2.2 on 20190228 - Add Debian i386 architecture
# Version: 2.3 on 20190327 - Add Debian security repository and did some formatting
# Version: 2.4 on 20190721 - Add Debian Buster
# Version: 2.5 Update script for github
#
# Usage:
# ./LinuxMirrorScript.sh
#
# Credits:
# https://www.tobanet.de/dokuwiki/debian:debmirror
# https://help.ubuntu.com/community/Debmirror
# https://gist.github.com/kleinig/3110783

# Variables
## Basic
rsync_exe="$(which rsync)"
createrepo_exe="$(which createrepo)"
reposync_exe="$(which reposync)"
mkdir_exe="$(which mkdir) -p"
logpath="/var/log/linux_mirror"
logfile="$logpath/$(date +%Y%m%d)_refresh_linux_repos.log"
start_date="$(date)"

## Repositories
base_url="mirror.netcologne.de"
base_local_repo="/var/www/repos"
centos_url="$base_url/centos"
centos_local_repo="$base_local_repo/centos"
centos_repos="os updates extras centosplus"
centos_versions="7 8"
epel_url="$base_url/fedora-epel"
epel_local_repo="$base_local_repo/epel"
debian_url="$base_url"
# Due to different syntax the two below variables have to be maintained independently. #
debian_versions="stretch,stretch-updates,buster,buster-updates"
debian_versions_security="stretch/updates,buster/updates"
#
debian_sections="main,contrib,non-free"
debian_arch="amd64,i386"
ubuntu_url="$base_url"
ubuntu_versions="bionic,bionic-security,bionic-updates,bionic-backports"
ubuntu_sections="main,restricted,universe,multiverse"
ubuntu_arch="amd64,i386"
third_repo="$base_local_repo/third"
third_repos="dl.iuscommunity.org/ius"

# Functions
_initialize() {
    ### Basic ###
    $mkdir_exe $logpath

    ### Operating System Repositories ###
    
    for repo in $centos_repos
    do
        for os_version in $centos_versions
        do
            echo "###################################################################################"
            echo "$(date) Ensuring CentOS $os_version $repo Repository Directory exists- Please wait...."
            if [ -d $centos_local_repo/$os_version/$repo/x86_64 ]
            then
                echo "Repository exists, moving on."
                echo "###################################################################################"
            else
                echo "Repository does not exist, creating it."
                $mkdir_exe $centos_local_repo/$os_version/$repo/x86_64
                echo "Done."
                echo "###################################################################################"
            fi
        done
    done

    ### EPEL Repositories ###
    
    for os_version in $centos_versions
    do
        echo "###################################################################################"
        echo "$(date) Ensuring EPEL $os_version Repository Directory exists- Please wait...."
        if [ -d $epel_local_repo/$os_version/x86_64 ]
        then
            echo "Repository exists, moving on."
            echo "###################################################################################"
        else
            echo "Repository does not exist, creating it."
            $mkdir_exe $epel_local_repo/$os_version/x86_64
            echo "Done."
            echo "###################################################################################"
        fi
    done
    
    ### Third Party Repositories ###
    
    for repo in $third_repos
    do
        echo "###################################################################################"
        echo "$(date) Ensuring $repo Repository Directory exists- Please wait...."
        if [ -d $third_repo/$repo ]
        then
            echo "Repository exists, moving on."
            echo "###################################################################################"
        else
            echo "Repository does not exist, creating it."
            $mkdir_exe $third_repo/$repo
            echo "Done."
            echo "###################################################################################"
        fi
    done
}

_update_centos_repos() {
    for repo in $centos_repos
    do
        for os_version in $centos_versions
        do
            echo "#################################################################################"
            echo "$(date) Fetching CentOS $os_version $repo Repository - Please wait...."
            $rsync_exe -avz --delete --exclude='repo*' rsync://$centos_url/$os_version/$repo/x86_64/ $centos_local_repo/$os_version/$repo/x86_64/
            echo "$(date) Finished. Updating local Repository:"
            $createrepo_exe --update $centos_local_repo/$os_version/$repo/x86_64
            echo "#################################################################################"
            echo
        done
    done
}

_update_epel_repos() {
    for os_version in $centos_versions
    do
        echo "###################################################################################"
        echo "$(date) Fetching CentOS $os_version EPEL Repository - Please wait...."
        $rsync_exe -avz --delete --exclude='repo*' rsync://$epel_url/$os_version/x86_64/ $epel_local_repo/$os_version/x86_64/
        echo "$(date) Finished. Updating local Repository:"
        $createrepo_exe --update $epel_local_repo/$os_version/x86_64
        echo "###################################################################################"
        echo
    done
}

_update_debian_repo() {
    echo "#################################################################################"
    echo "$(date) Updating Debian Repository:"
    debmirror "${base_local_repo}/debian" --no-check-gpg -r debian -p --nosource --method=rsync --host=${debian_url} --dist=${debian_versions} --section=${debian_sections} --arch=${debian_arch} --cleanup
    # no-check-gpg as workaround!?
    echo "#################################################################################"
    echo
}

_update_debian_security_repo() {
    echo "#################################################################################"
    echo "$(date) Updating Debian Security Repository:"
    debmirror "${base_local_repo}/debian-security" --no-check-gpg -r debian-security -p --nosource --method=rsync --host=${debian_url} --dist=${debian_versions_security} --section=${debian_sections} --arch=${debian_arch} --cleanup
    # no-check-gpg as workaround!?
    echo "#################################################################################"
    echo
}

_update_ubuntu_repo() {
    echo "#################################################################################"
    echo "$(date) Updating Ubuntu Repository:"
    debmirror "${base_local_repo}/ubuntu" --no-check-gpg -r ubuntu -p --nosource --method=rsync --host=${ubuntu_url} --dist=${ubuntu_versions} --section=${ubuntu_sections} --arch=${ubuntu_arch} --cleanup
    # no-check-gpg as workaround!?
    echo "#################################################################################"
    echo
}

_update_third_party_repos() {
    for repo in $third_repos
    do
        echo "#################################################################################"
        echo "$(date) Fetching $repo Repository - Please wait...."
        $rsync_exe -avz --delete --exclude='archive/*' --exclude='development/*' --exclude='testing/*' --exclude='*/5/*' --exclude='*/6/*' --exclude='*/i386/*' --exclude='*/repoview/*' rsync://$repo/* $third_repo/$repo/
        echo "$(date) Finished. Updating local Repository:"
        $createrepo_exe --update $third_repo/$repo
        echo "#################################################################################"
        echo
    done
}

_update_reposync_repos() {
	for repo in $reposync_repos
	do
		echo "#################################################################################"
		echo "$(date) Fetching $repo Repository - Please wait...."
		$reposync_exe --arch=$reposync_arch --repoid=$repo --download_path=$third_repo/ --downloadcomps --download-metadata --delete
		echo "$(date) Finished. Updating local Repository:"
		$createrepo_exe --update $third_repo/$repo
		echo "#################################################################################"
	done
}

_finalize() {
    echo
    echo "#################################################################################"
    echo
    echo "### Fixing permissions ###n"
    chmod 770 -R /var/www
    echo
    echo "### Fixing ownership ###"
    chown apache:apache -R /var/www
    echo
    echo "### Fixing SELinux context ###"
    chcon -Rt httpd_sys_content_t /var/www
    echo
    echo "### Mirror size ###"
    echo
    df -hP | head -1
    df -hP | grep "$base_local_repo"
    echo
    echo "### Started on $start_date ###"
    echo "### Finished on $(date) ###"
    echo
    echo "#################################################################################"
}

# Main
_initialize 2>&1 >> $logfile
_update_centos_repos  2>&1 >> $logfile
_update_epel_repos  2>&1 >> $logfile
_update_debian_repo 2>&1 >> $logfile
_update_debian_security_repo 2>&1 >> $logfile
_update_ubuntu_repo 2>&1 >> $logfile
_update_third_party_repos 2>&1 >> $logfile
_finalize 2>&1 >> $logfile
exit 0
