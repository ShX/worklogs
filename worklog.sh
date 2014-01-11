#!/bin/bash

#TODO add workspaces
#TODO task folder name format DT::TAG::NAME

#set -x # debug

###############################################################################
## Enviroment      ############################################################

WLDIR=~/Worklogs
WLCUR=$WLDIR/_CURRENT
WLTODAY=$WLDIR/`date +%Y-%m-%d`

NOTES=notes.txt
WLNOTE=$WLCUR/$NOTES

###############################################################################
## Functions       ############################################################

task_select() {
    _ifs=$IFS

    search=${1-today}

    task=''
    while [ -z "$task" ]; do
        PS3=Select\ tasks\ \($search\):

        IFS=$'\n'
        tasks=( $(wl ls $search)  )
        echo '0) change period'
        select task in  "${tasks[@]}"; do
            echo DEBUG: $REPLY\) $task
            if [ $REPLY -eq 0 ]; then
                read search
                break
            elif [ -e "$WLDIR/$task" ]; then
                echo Selected task: $task
                break
            else
                continue
            fi
        done

    done;

    IFS=$_ifs
    return task
}

###############################################################################
## Logic           ############################################################

cmd=${1-help}

case $cmd in
    close)
        message="${*:2}"
        if [ -z $message ]; then
            message="stop"
        fi
        wl note $message
        rm $WLCUR
        cd
        export PS1="$ "
        #todo restore PS1
    ;;

    cp|copy)
        search="$2"
        task=''
        while [ -z "$task" ]; do
            PS3=Select\ tasks\ \($search\):\
            _ifs=$IFS
            IFS=$'\n'
            tasks=( $(wl ls $search)  )
            echo '0) change period'
            select task in  "${tasks[@]}"; do
                echo DEBUG: $REPLY\) $task
                if [ $REPLY -eq 0 ]; then
                    read search
                    break
                elif [ -e "$WLDIR/$task" ]; then
                    echo Selected task: $task
                    break
                else
                    continue
                fi
            done
            IFS=$_ifs
        done;

        name=${task:11}

        wl create $name

        ln -s "../$task/$NOTES" $WLNOTE
        echo -n "Link files"
        for file in $(ls ../$task); do
            echo
            read -p "File: $file. Create link? (Y/N): " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ln -s "../$task/$file"
            fi
            echo
        done
        wl note continue
    ;;

    create)
        WLTASK="$WLTODAY ${*:2}"
        mkdir "$WLTASK"
        cd "$WLTASK"
        if [ -L "$WLCUR" ]; then
            rm "$WLCUR"
        elif [ -e "$WLCUR" ]; then
            echo "ERROR";
        fi
        ln -s "$WLTASK" "$WLCUR"
        wl current
        #note created
    ;;

    current|home)
        cd -P $WLCUR
        name=${PWD##*/} # current directory name
        name=${name:11} # remove date from name (11 characters)
        export PS1="\[\033[0;32m\]Task\[\033[0;35m\]:\[\033[0;34m\] $name\n\[\033[0;31m\]\$\[\033[0m\] "
    ;;

    ls|list)
        case "$2" in
            "empty")
                find $WLDIR/* -type d -prune -empty -printf %f\\n | sort -r
            ;;
            "today")
                find $WLDIR/* -type d -prune -daystart -ctime 0 -printf %f\\n | sort -r
            ;;
            "days")
                find $WLDIR/* -type d -prune -ctime -$3 -printf %f\\n | sort -r
            ;;
            "month")
                find $WLDIR/* -type d -prune -name `date +%Y-%m-`* -printf %f\\n | sort -r
            ;;
            "week")
                find $WLDIR/* -type d -prune -ctime -6 -printf %f\\n | sort -r
            ;;
            *)
                find $WLDIR/* -type d -prune -ctime -1 -printf %f\\n | sort -r
        esac
    ;;

    note)
        echo -n "$(date +%Y-%m-%d\ %T) " >> $WLNOTE
        if [ $# -eq 1 ]; then
            cat | tr '\n' '\n\t' >> $WLNOTE
        else
            echo "${*:2}" | tr '\n' '\n\t' >> $WLNOTE
        fi
    ;;

    notes)
        less $WLNOTE
    ;;

    open)
        search=${2-today}
        task=''
        while [ -z "$task" ]; do
            PS3=Select\ tasks\ \($search\):\
            _ifs=$IFS
            IFS=$'\n'
            tasks=( $(wl ls $search)  )
            echo '0) change period'
            select task in  "${tasks[@]}"; do
                echo DEBUG: $REPLY\) $task
                if [ $REPLY -eq 0 ]; then
                    read search
                    break
                elif [ -e "$WLDIR/$task" ]; then
                    echo Selected task: $task
                    break
                else
                    continue
                fi
            done
            IFS=$_ifs
        done;

        wl note close \(switch to $task\)
        rm $WLCUR
        WLTASK="$WLDIR/$task"
        ln -s "$WLTASK" "$WLCUR"
        wl current
        wl note resume
    ;;

    rm|remove)
        echo "TODO";
    ;;

    search)
        if [ $# -eq 2 ]; then
            query=$2
            find "$WLDIR" -type d -iname "*$query*" -printf %f\\n | sort -r
        else
            echo "ERROR";
        fi
    ;;

    ## setup

    setup)
        WLHOME=${1-~/Worklogs}
        if [ ! -e $WLHOME ]; then
            mkdir -p $WLHOME
        fi
        echo "## Worklogs"             >> .bashrc
        echo "export WLHOME=$WLHOME"   >> .bashrc
        echo "alias wl='. worklog.sh'" >> .bashrc
    ;;

    help)
        FILE=${BASH_SOURCE##*/}
        COMMAND=$(alias -p | grep $FILE | sed "s/.*alias \(.*\)=.*/\1/")
        if [ -z $COMMAND ]; then
            COMMAND=$FILE
        fi

        echo "Simple Worklogs mangement"
        echo "Usage:"
        echo "       $COMMAND create - create new task"
        echo "       $COMMAND open   - switch task"
        echo "       $COMMAND close - "
        echo "       $COMMAND  - "
        echo "       $COMMAND  - "
        echo "Current task:"
        echo "       $COMMAND current        - goto task folder"
        echo "       $COMMAND note [message] - add note"
        echo "       $COMMAND notes          - show all notes"
        echo "       $COMMAND close          - add note about close and stop working"
    ;;
    ## func
esac
