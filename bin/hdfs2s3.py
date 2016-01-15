#!/usr/bin/python
from __future__ import print_function

#TITLE: dhfs2s3
#AUTHORS: Elena Mishkina, Alexey Kuksin, Alex Pivovarov
#DATE: 2016-01-15
#OBJECTIVE: Uploads files from HDFS to s3 object store

# Script copies files from hdfs folders to s3 object store.
# Follow the prompt's questions.
# If you'd like to run script with input parameters the following order is expected:
# ./hdfs2s3.py <HDFS root source folder> <s3 destination path> <s3 access_key> <s3 secret_key> <s3 writing option - update/overwrite>

import os, sys, subprocess, re


prompt = '> '


def exec_shell(command):

   try:
        print("Execute shell command: " + command )

        process = subprocess.Popen('/bin/bash', stdin=subprocess.PIPE, stdout=subprocess.PIPE)

        out, err =  process.communicate(command)

        print("Exec Stdout: ", out,"\nExec Error:",err,"\n")

        return out, err

   except:
        e = sys.exc_info()

        print("exec_shell failed: ", e)

        ret = raw_input("Would you like to continue?\n" + prompt)

        if re.match(ret, 'yes', re.IGNORECASE):

            return None,None

        else:
            print("Unexpected error:", sys.exc_info())

            sys.exit(-1)


def add_path(repopath, command):
    return '''
cd ''' + repopath + ''' +
''' + command + '''
'''


class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg


def main(argv=None):

    hdfs_root_dir, s3_dest_path, s3_access_key, s3_secret_key, distcp_writing_option = "","","","",""

    if argv is None:
        argv = sys.argv
        print("Lenght of arguments is: ", len(argv) )

    try:
        if len(argv) in range(3,7):
            try:
                for id,val in enumerate(argv):

                    if id == 1:
                        hdfs_root_dir = str(argv[1])

                    if id == 2:
                        s3_dest_path = str(argv[2])

                    if id == 3:
                        s3_access_key = str(argv[3])

                    if id == 4:
                        s3_secret_key = str(argv[4])

                    if id == 5:
                        distcp_writing_option = str(argv[5])

            except:
                print("Unexpected error:", sys.exc_info())

                sys.exit(0)

        else:
           print("hadoop distcp will be applying for each subfloder starting from the root folder you specified. \nPlease answer questions below.")

           hdfs_root_dir = raw_input("Enter source HDFS root folder:\n" + prompt)

           s3_dest_path = raw_input("Enter s3 destination root path without last slash :\n" + prompt)

           s3_access_key = raw_input("(Optional, just enter to ignore.) Enter s3 access_key:\n" + prompt)

           s3_secret_key = raw_input("(Optional, just enter to ignore.) Enter s3 secret key:\n" + prompt)

           distcp_writing_option = raw_input("(Optional, just enter to ignore.) Enter s3 writing option - update/overwrite:\n" + prompt)

        cmd = "hadoop distcp "

        if len(distcp_writing_option)>1:
            cmd = cmd + "-" + distcp_writing_option

        if len(hdfs_root_dir)>1:
            cmd = cmd + " " + hdfs_root_dir
        else:
            print("Source path should be specified.")
            sys.exit(-1)

        if len(s3_dest_path)>1:
            s3 = "s3n://" if re.match("^s3n://",s3_dest_path) else "s3://"

            s3_dest_path = s3  + s3_access_key + ":" + s3_secret_key + "@" + re.sub(r"s3n://|s3://",r"",s3_dest_path) \
                        if len(s3_access_key)>1 and len(s3_secret_key)>1 else s3 + re.sub(r"s3n://|s3://",r"",s3_dest_path)

        else:
            print("Destination path should be specified.")
            sys.exit(-1)

        # get list of HDFS subfolders

        print("HDFS root folder is: ",hdfs_root_dir, "\ns3 destination folder is: ",s3_dest_path, \
              "\nspecified distcp writing option is: ", distcp_writing_option)

        out, err = exec_shell("hadoop fs -ls  " + hdfs_root_dir)

        if len([lines for lines in out.splitlines(True) if re.match(r'^d',lines)])>0:

           for line in [lines for lines in out.splitlines(True) if re.match(r'^d',lines)]:

                print("Starting copy hdfs folder: " +  line.rsplit('/')[-1].rstrip('\n'))

                if len(distcp_writing_option) > 0:
                    distcp_command=cmd + "/"+line.rsplit('/')[-1].rstrip('\n') +" "+ s3_dest_path +"/"+ line.rsplit('/')[-1].rstrip('\n')+"/"

                else:
                    distcp_command=cmd + "/"+line.rsplit('/')[-1].rstrip('\n') +" "+ s3_dest_path

                exec_shell(distcp_command)
        else:
            distcp_command = cmd +  " " + s3_dest_path if len(distcp_writing_option) == 0 else cmd +  " " + s3_dest_path +"/" + hdfs_root_dir.rsplit('/')[-1].rstrip('\n')

            exec_shell(distcp_command)

        print("Process done.")

    except Usage, err:

        print >>sys.stderr, err.msg

        print >>sys.stderr, "for help use --help"

        return 2


if __name__ == "__main__":

    sys.exit(main())
