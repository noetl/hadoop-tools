#!/usr/bin/python
from __future__ import print_function

# Script runs copy from hdfs folders to s3 object store.
# Follow the prompt's questions.
# If you'd like to run script with input parameters the following order is expected:
# ./cphdfs2s3.py <HDFS root source folder> <s3 destination path> <s3 access_key> <s3 secret_key> <s3 writing option update/overwrite>


import os, sys, subprocess, re


prompt = '> '


def exec_shell(commands):
   try:
        process = subprocess.Popen('/bin/bash', stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        out, err =  process.communicate(commands)
        print("Stdout: ", out,"\nError:",err,"\n")
        return out, err
   except:
        e = sys.exc_info()
        print("exec_shell failed: ", e)
        ret = raw_input("Would you like to continue?\n" + prompt)
        if re.match(ret, 'yes', re.IGNORECASE):
            return None,None
        else:
            sys.exit(main())


def add_path(repopath, command):
    return '''
cd ''' + repopath + ''' +
''' + command + '''
'''


def assign_vars(*args):
    try:
        return str(args[1]),str(args[2]),str(args[3]),str(args[4]),str(args[5])
    except:
        return None, None, None


class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg


def main(argv=None):
    global hdfs_root_dir, s3_dest_path, s3_access_key, s3_secret_key, distcp_writing_option

    if argv is None:
        argv = sys.argv
        print("Lenght of arguments is: ", len(argv) )

    try:
        if len(argv)==5:
            hdfs_root_dir, s3_dest_path, s3_access_key, s3_secret_key, distcp_writing_option = assign_vars(*argv)
        else:
            print("hadoop distcp will be applying for each subfloder starting from the root folder you specified. \nPlease answer questions below.")
            hdfs_root_dir = raw_input("Enter source HDFS root folder:\n" + prompt)
            s3_dest_path = raw_input("Enter s3 destination root path:\n" + prompt)
            s3_access_key = raw_input("(Optional, just enter to ignore.) Enter s3 access_key:\n" + prompt)
            s3_secret_key = raw_input("(Optional, just enter to ignore.) Enter s3 secret key:\n" + prompt)
            distcp_writing_option = raw_input("(Optional, just enter to ignore.) Enter s3 writing option - update/overwrite:\n" + prompt)
            cmd = "hadoop distcp "
            if hdfs_root_dir is not None:
                cmd = cmd + hdfs_root_dir
            if distcp_writing_option is not None:
                cmd = cmd + " -" + distcp_writing_option
            if s3_dest_path is not None and s3_access_key is not None and s3_secret_key is not None:
                s3_dest_path = cmd + "s3n://" + s3_access_key + ":" + s3_access_key + "@" + re.sub(r"s3n://|s3://",r"",s3_dest_path)
            elif s3_dest_path is not None:
                s3_dest_path = cmd + "s3n://" + re.sub(r"s3n://|s3://",r"",s3_dest_path)


        # get list of HDFS subfolders

        print("HDFS root folder is: ",hdfs_root_dir, "\ns3 destination folder is: ",s3_dest_path, \
              "\nspecified distcp writing option is: ", s3_writing_option)
        out, err = exec_shell("hadoop fs -ls " + hdfs_root_dir)

        for line in out.splitlines(True):
            print("starting copy hdfs floder: " +  line.rsplit('/')[-1].rstrip('\n'))


        print("Process done.")

    except Usage, err:
        print >>sys.stderr, err.msg
        print >>sys.stderr, "for help use --help"
        return 2


if __name__ == "__main__":
    sys.exit(main())
