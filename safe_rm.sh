#!/bin/bash

# ----
# Author: Isuru W.
# File: safe_rm
# Usage: safe_rm -i|-v|-r|-R [FILE] [FILE] ...
# ----

#---- Paths ----
trash="$HOME/deleted/"
trashcfg_file="$HOME/.rm.cfg"
resinf_file="$HOME/.restore.info"
#---- End of paths ----

#---- Helper functions ----

function interactive {
        # ----
        # $1 = path to the file/dir to be moved into trash
        # User will be prompted to confim deletion of the file.
        # Returns 1 if 'y' and 0 if 'n'; '0' in all other cases.
        # ----

        read -p "safe_rm: remove file '$1'? " opt
        case $opt in
                [Yy]|Yes|yes|YES)
                dflag=1;;
                [Nn]|No|no|NO)
                dflag=0;;
                *)
                dflag=0;;
        esac
        echo $dflag
}

function mv_file_dir {
        # ----
        # $1 = path to the file/dir to be moved into trash
        # $2 = iflag : 1 if active, 0 otherwise
        # $3 = vflag : 1 if active, 0 otherwise
        # File info sent to $HOME/.restore.info and moves file to trash.
        # -i and -v functions based on value of $2 and $3.
        # ----

        #check for iflag
        dflag=1 #delete flag, keeps track of -i response
        if [ $2 -eq 1 ];
        then
                dflag=$(interactive $1)
        fi

        if [ $dflag -eq 1 ];
        then
                echo $(basename $1)"_"$(ls -id $1 | cut -f 1 -d " "):$(readlink -m $1) >> $resinf_file
                mv $1 $trash$(basename $1)"_"$(ls -id  $1 | cut -f 1 -d " ")
        fi

        #check for vflag
        if [ $3 -eq 1 ] && [ $dflag -eq 1 ];
        then
                echo "safe_rm: removed '$1'" >&1
        fi
}

function dir_recurse {
        # ----
        # $1 = directory to recurese
        # $2 = iflag : 1 if active, 0 otherwise
        # $3 = vflag : 1 if active, 0 otherwiss
        # Recurses the given dir and moves file by file into trash.
        # Also recurses into sub-directories of the dir given.
        # ----

        for file in $(ls -a $1)
        do
                if [ $file == "." ] || [ $file == ".." ];
                then
                        continue
                elif [ -f "$1/$file" ];
                then
                        #removes file in dir
                        mv_file_dir "$1/$file" $2 $3
                else

                        descend=1
                        if [ $2 -eq 1 ];
                        then
                                read -p "safe_rm: descend into directory '$1/$file'? " opt
                                case $opt in
                                        [yY]|Yes|yes|YES)
                                        descend=1;;
                                        *)
                                        descend=0;;
                                esac
                        fi

                        if [ $descend -eq 1 ];
                        then
                                #recurse into sub-dir 
								dir_recurse "$1/$file" $2 $3
                        fi
                fi
        done

        #removed the current dir
        if [ $(ls -a $1 | wc -l ) -eq 2 ];
        then
                mv_file_dir $1 $2 $3
        fi
}

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
                #make dir accordingly
                mkdir -p $trash
        fi
}

#---- End of helper functions ----

#trash path and creation
set_trash

#parameter processing
iflag=0
vflag=0
rflag=0
while getopts ivrR opt
do
        case "$opt" in
        i) iflag=1;;
		v) vflag=1;;
        r) rflag=1;;
        R) rflag=1;;
        *) #unknown flag
            echo "usage: safe_rm -i|-v|-r|-R [FILE] [FILE] ..." >&2
            exit 1;;
        esac
done
shift $(($OPTIND - 1))

if [ $# -eq 0 ];
then
        echo "safe_rm: missing operand" >&2
        exit 1
fi

#start processing files/dirs
stat=0 #keeps track of exit status
for file in "$@"
do
        if [ ! -e $file ];
        then
                #does file exist?
                echo "safe_rm: cannot remove '$file': no such file or directory" >&2
                stat=1
                continue
        fi

        if [ -f $file ];
        then
                #process file
                mv_file_dir $file $iflag $vflag
        elif [ $rflag -eq 1 ] && [ -d $file ];
        then
                #process dir
                dir_recurse $file $iflag $vflag
        else
                echo "safe_rm: cannot remove '$file': is a directory" >&2
                stat=1
        fi
done

exit $stat
