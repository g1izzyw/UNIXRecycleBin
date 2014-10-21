#!/bin/bash

# ----
# Author: Isuru Weerasooriya
# File: safe_rm_restore
# Usage: sage_rm_restore [FILE_INODE]
# ----

#---- Paths ----
trash="$HOME/deleted"
trashcfg_file="$HOME/.rm.cfg"
resinf_file="$HOME/.restore.info"
#---- End of paths ----

#---- Helper functions ----

function set_trash {
        # ----
        # Sets the trash path and creates the trash dir
        # if it does not exist.
        # ----

        if [ -e $trashcfg_file ];
        then
                #.rm.cfg case
                trash="$(cat $trashcfg_file)"
        fi

        if [ ! -z $RMCFG ];
        then
                #RMCFG environment var case
                trash="$RMCFG"
        fi

        if [ ! -d $trash ];
        then
                #creates trash
                mkdir -p $trash
        fi
}

function res_file_dir {
        # ----
        # $1 = file/dir path to be moved
        # $2 = deleted directory path
        # $3 = destination path for file/dir, including its new name
        # Moves the file from '$2/$1' to '$3'.
        # ----

        mv "$2/$1" $3
        cat $resinf_file | egrep -v "^$1:.*" > tmp_file_resinf
        cat tmp_file_resinf > $resinf_file
        rm tmp_file_resinf
}

function restore {
        # ----
        # $1 = The path we want to restore
        # Restore all parent directories to '$1'.
        # ----

        #base name and dir path of/to file
        typeset dir_name=$(dirname $1)
        typeset base_name=$(basename $1)

        if [ ! -e $dir_name ];
        then
                #recurse if parent dir does not exist
                restore $dir_name
        fi

        if [ $(egrep ".*:$1$" $resinf_file | wc -l) -eq 0 ];
        then
                #make dir if not in .restore.info
                mkdir $1
        else
                #file info in .restore.info
                #instead of mkdir we want to move file from deleted
                move_dir=$(egrep ".*:$1$" $resinf_file | head -n 1 | cut -d : -f 1)
                #for i in $line
                #do
                #mdir=$(cut -d : -f 1 <<< $line)

                if [ -d $trash/$move_dir ];
                then
                        res_file_dir $move_dir $trash $1
                        #break
                fi
                #done
        fi
}

#---- End of helper functions ----

#trash path and creation
set_trash

#parameter parsing
if [ $# -eq 0 ] || [ $# -gt 1 ];
then
        echo "safe_rm_restore: incorrect number of operands" >&2
        echo "usage: safe_rm_restore [FILE_INODE]" >&2
        exit 1
fi

#check if file in .restore.info
if [ $(cat $resinf_file | egrep "^$1:.*" | wc -l) -gt 0 ];
then
        #check if the file in the deleted
        if [ ! -e "$trash/$1" ];
        then
                echo "safe_rm_restore: no such file '$1'" >&2
                exit 1
        fi

        #file path, seperate into base name and dir path
        f_path=$(cat $resinf_file | egrep "^$1:.*" | cut -d : -f 2)
        dir_name=$(dirname $f_path)
        base_name=$(basename $f_path)

        if [ ! -d $dir_name  ];
        then
                #restore all parent dir, if they do not exist
                restore $dir_name
        fi

        overw=1 #keep track of overwrite input
        if [ -e $f_path ];
        then
                read -p "safe_rm_restore: file already exists, overwrite? " opt
                case $opt in
                        [Yy]|Yes|yes|YES)
                        overw=1;;
                        *) #anything else - we assume 'no'
                        exit 0;;
                esac
        fi

        if [ $overw -eq 1 ];
        then
                #move(restore) the requested file/dir
                res_file_dir $1 $trash $f_path
        fi
else
        echo "safe_rm_restore: no such file '$1'" >&2
        exit 1
fi

exit 0
