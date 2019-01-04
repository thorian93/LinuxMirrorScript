#!/bin/env bash
# Linux Mirror Server Refresh Script v 1.0
# Robin Gierse (thorian@robingierse.de)
# 2018-03-28: Initial commit. Script is productive.
# 2018-05-07: Update Script with third party repository of iuscommunity.org
# 2018-10-06: Update script with some improvements
# 2018-12-02: Add debmirror abilities for debian
# 2018-12-17: Add debmirror abilities for ubuntu
# 2018-12-19: Add rsync abilities for fedora - still testing
# 2018-12-30: Add torproject repository - still testing
# 2019-01-02: Add Ubuntu Bionic release
# Credits:
# https://www.tobanet.de/dokuwiki/debian:debmirror
# https://help.ubuntu.com/community/Debmirror

# Variables
## Basic
RSYNC="$(which rsync)"
WGET="$(which wget)"
MKDIR="$(which mkdir) -p"
LOGPATH="/var/log/linux_mirror"
LOGFILE="$LOGPATH/$(date +%Y%m%d)_refresh_linux_repos.log"

## Repository
BASE_URL="mirror.netcologne.de"
BASE_LOCAL_REPO="/var/www/repos"
CENTOS_URL="$BASE_URL/centos"
CENTOS_LOCAL_REPO="$BASE_LOCAL_REPO/centos"
CENTOS_REPOS="os updates extras centosplus"
CENTOS_VERSIONS="7"
FEDORA_URL="$BASE_URL/fedora"
FEDORA_LOCAL_REPO="$BASE_LOCAL_REPO/fedora"
FEDORA_REPOS="Everything Modular"
FEDORA_VERSIONS="29"
EPEL_URL="$BASE_URL/fedora-epel"
EPEL_LOCAL_REPO="$BASE_LOCAL_REPO/epel"
DEBIAN_URL="$BASE_URL"
DEBIAN_VERSIONS="jessie,jessie-updates,stretch,stretch-updates"
DEBIAN_SECTIONS="main,contrib,non-free"
DEBIAN_ARCH="amd64"
UBUNTU_URL="$BASE_URL"
UBUNTU_VERSIONS="bionic,bionic-security,bionic-updates"
UBUNTU_SECTIONS="main,restricted,universe,multiverse"
UBUNTU_ARCH="amd64,i386"
THIRD_REPO="$BASE_LOCAL_REPO/third"
THIRD_REPOS="dl.iuscommunity.org/ius"

# Functions
initialize() {
    ### Basic ###
    
    $MKDIR $LOGPATH

    ### Operating System Repositories ###
    
    for REPO in $CENTOS_REPOS
    do
        for OS_VERSION in $CENTOS_VERSIONS
        do
            echo "###################################################################################"
            echo "$(date) Ensuring CentOS $OS_VERSION $REPO Repository Directory exists- Please wait...."
            if [ -d $CENTOS_LOCAL_REPO/$OS_VERSION/$REPO/x86_64 ]
            then
                echo "Repository exists, moving on."
                echo "###################################################################################"
            else
                echo "Repository does not exist, creating it."
                $MKDIR $CENTOS_LOCAL_REPO/$OS_VERSION/$REPO/x86_64
                echo "Done."
                echo "###################################################################################"
            fi
        done
    done

    for REPO in $FEDORA_REPOS
    do
        for OS_VERSION in $FEDORA_VERSIONS
        do
            echo "###################################################################################"
            echo "$(date) Ensuring Fedora $OS_VERSION $REPO Repository Directory exists- Please wait...."
            if [ -d $FEDORA_LOCAL_REPO/linux/releases/$OS_VERSION/$REPO/x86_64/os ]
            then
                echo "Repository exists, moving on."
                echo "###################################################################################"
            else
                echo "Repository does not exist, creating it."
                $MKDIR $FEDORA_LOCAL_REPO/linux/releases/$OS_VERSION/$REPO/x86_64/os
                echo "Done."
                echo "###################################################################################"
            fi
            echo "###################################################################################"
            echo "$(date) Ensuring Fedora $OS_VERSION $REPO Updates Repository Directory exists- Please wait...."
            if [ -d $FEDORA_LOCAL_REPO/linux/updates/$OS_VERSION/$REPO/x86_64 ]
            then
                echo "Repository exists, moving on."
                echo "###################################################################################"
            else
                echo "Repository does not exist, creating it."
                $MKDIR $FEDORA_LOCAL_REPO/linux/updates/$OS_VERSION/$REPO/x86_64
                echo "Done."
                echo "###################################################################################"
            fi
        done
    done

    ### EPEL Repositories ###
    
    for OS_VERSION in $CENTOS_VERSIONS
    do
        echo "###################################################################################"
        echo "$(date) Ensuring EPEL $OS_VERSION Repository Directory exists- Please wait...."
        if [ -d $EPEL_LOCAL_REPO/$OS_VERSION/x86_64 ]
        then
            echo "Repository exists, moving on."
            echo "###################################################################################"
        else
            echo "Repository does not exist, creating it."
            $MKDIR $EPEL_LOCAL_REPO/$OS_VERSION/x86_64
            echo "Done."
            echo "###################################################################################"
        fi
    done
    
    ### Third Party Repositories ###
    
    for REPO in $THIRD_REPOS
    do
        echo "###################################################################################"
        echo "$(date) Ensuring $REPO Repository Directory exists- Please wait...."
        if [ -d $THIRD_REPO/$REPO ]
        then
            echo "Repository exists, moving on."
            echo "###################################################################################"
        else
            echo "Repository does not exist, creating it."
            $MKDIR $THIRD_REPO/$REPO
            echo "Done."
            echo "###################################################################################"
        fi
    done
}

update_centos_repos() {
    for REPO in $CENTOS_REPOS
    do
        for OS_VERSION in $CENTOS_VERSIONS
        do
            echo "#################################################################################"
            echo "$(date) Fetching CentOS $OS_VERSION $REPO Repository - Please wait...."
            $RSYNC -avz --delete --exclude='repo*' rsync://$CENTOS_URL/$OS_VERSION/$REPO/x86_64/ $CENTOS_LOCAL_REPO/$OS_VERSION/$REPO/x86_64/
            echo "$(date) Finished. Updating local Repository:"
            createrepo --update $CENTOS_LOCAL_REPO/$OS_VERSION/$REPO/x86_64
            echo "#################################################################################"
            echo
        done
    done
}

update_fedora_repos() {
    for REPO in $FEDORA_REPOS
    do
        for OS_VERSION in $FEDORA_VERSIONS
        do
            echo "#################################################################################"
            echo "$(date) Fetching Fedora $OS_VERSION $REPO Repository - Please wait...."
            $RSYNC -avz --delete rsync://$FEDORA_URL/linux/releases/$OS_VERSION/$REPO/x86_64/os/ $FEDORA_LOCAL_REPO/linux/releases/$OS_VERSION/$REPO/x86_64/os/
            echo "$(date) Finished. Updating local Repository:"
            createrepo --update $FEDORA_LOCAL_REPO/linux/releases/$OS_VERSION/$REPO/x86_64/os
            echo "#################################################################################"
            echo
            echo "#################################################################################"
            echo "$(date) Fetching Fedora $OS_VERSION $REPO Updates Repository - Please wait...."
            $RSYNC -avz --delete rsync://$FEDORA_URL/linux/updates/$OS_VERSION/$REPO/x86_64/os/ $FEDORA_LOCAL_REPO/linux/updates/$OS_VERSION/$REPO/x86_64/
            echo "$(date) Finished. Updating local Repository:"
            createrepo --update $FEDORA_LOCAL_REPO/linux/updates/$OS_VERSION/$REPO/x86_64
            echo "#################################################################################"
            echo
        done
    done
}

update_epel_repos() {
    for OS_VERSION in $CENTOS_VERSIONS
    do
        echo "###################################################################################"
        echo "$(date) Fetching CentOS $OS_VERSION EPEL Repository - Please wait...."
        $RSYNC -avz --delete --exclude='repo*' rsync://$EPEL_URL/$OS_VERSION/x86_64/ $EPEL_LOCAL_REPO/$OS_VERSION/x86_64/
        echo "$(date) Finished. Updating local Repository:"
        createrepo --update $EPEL_LOCAL_REPO/$OS_VERSION/x86_64
        echo "###################################################################################"
        echo
    done
}

update_gpg_keys() {
    echo "#################################################################################"
    echo "$(date) Updating APT GPG Keys - Please wait...."
    gpg --no-default-keyring --keyring trustedkeys.gpg --import /usr/share/keyrings/debian-archive-keyring.gpg 2>&1 >> $LOGFILE
    #gpg --no-default-keyring --keyring trustedkeys.gpg --import /usr/share/keyrings/ubuntu-archive-keyring.gpg 2>&1 >> $LOGFILE
    # Import directly from key srv?!
    echo "#################################################################################"
}

update_debian_repo() {
    echo "#################################################################################"
    echo "$(date) Updating Debian Repository:"
    debmirror "${BASE_LOCAL_REPO}/debian" -r debian -p --nosource --method=rsync --host=${DEBIAN_URL} --dist=${DEBIAN_VERSIONS} --section=${DEBIAN_SECTIONS} --arch=${DEBIAN_ARCH} --cleanup
    echo "#################################################################################"
    echo
}

update_ubuntu_repo() {
    echo "#################################################################################"
    echo "$(date) Updating Ubuntu Repository:"
    debmirror "${BASE_LOCAL_REPO}/ubuntu" --no-check-gpg -r ubuntu -p --nosource --method=rsync --host=${UBUNTU_URL} --dist=${UBUNTU_VERSIONS} --section=${UBUNTU_SECTIONS} --arch=${UBUNTU_ARCH} --cleanup
    # no-check-gpg as workaround!?
    echo "#################################################################################"
    echo
}

update_third_party_repos() {
    for REPO in $THIRD_REPOS
    do
        echo "#################################################################################"
        echo "$(date) Fetching $REPO Repository - Please wait...."
        $RSYNC -avz --delete --exclude='archive/*' --exclude='development/*' --exclude='testing/*' --exclude='*/5/*' --exclude='*/6/*' --exclude='*/i386/*' --exclude='*/repoview/*' rsync://$REPO/* $THIRD_REPO/$REPO/
        echo "$(date) Finished. Updating local Repository:"
        createrepo --update $THIRD_REPO/$REPO
        echo "#################################################################################"
        echo
    done
    # https://www.torproject.org/docs/running-a-mirror.html.en
    echo "#################################################################################"
    echo "$(date) Fetching Tor Project Repository - Please wait...."
    $RSYNC -avz --delete --exclude="dist"  rsync://rsync.torproject.org/website-mirror/ "$THIRD_REPO/torproject"
    $RSYNC -avz --delete rsync://rsync.torproject.org/dist-mirror/ "$THIRD_REPO/torproject/dist"
    echo "$(date) Finished. Updating local Repository:"
    createrepo --update $THIRD_REPO/$REPO
    echo "#################################################################################"
    echo
}

finalize() {
    chmod 770 -R /var/www
    chown apache:apache -R /var/www
    chcon -Rt httpd_sys_content_t /var/www
}

# Main
initialize 2>&1 >> $LOGFILE
update_centos_repos  2>&1 >> $LOGFILE
update_fedora_repos  2>&1 >> $LOGFILE
update_epel_repos  2>&1 >> $LOGFILE
update_gpg_keys 2>&1 >> $LOGFILE
update_debian_repo 2>&1 >> $LOGFILE
update_ubuntu_repo 2>&1 >> $LOGFILE
update_third_party_repos 2>&1 >> $LOGFILE
finalize 2>&1 >> $LOGFILE
exit 0