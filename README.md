UNIXRecycleBin
==============

The ‘safe_rm’ command attempts to mimics the UNIX ‘rm’ command behaviour with the exception of permanently removing the file from system. Instead the file will be moved into a deleted and can be restored using the ‘safe_rm_restore’. The usage of the two commands are as below.

Usage: safe_rm -i|-v|-r|-R [FILE] [FILE] ...
Usage: sage_rm_restore [FILE_INODE]

When the ‘safe_rm’ command is used, the file will be moved to a ‘deleted’ folder. The deleted folder is located in ‘$HOME/deleted/’ by default. This location can be overridden by setting a path in the file ‘.rm.cfg’, located at ‘$HOME/.rm.cfg’. Both of the previous paths can be overridden by setting a ‘RMCFG’ environment variable with the path of the recycling bin.

When file is being moved into the recycle bin, the file information will be stored in ‘.restore.info’ located at ‘$HOME/.restore.info’. This file information will then be used when a file is being restored.

The safe_rm command supports interactive mode, verbose and recursive functionality of the UNIX rm command.