#!/usr/bin/python
from __future__ import print_function

#TITLE: hdfs2s3
#AUTHORS: Alexey Kuksin, Elena Mishkina, Alex Pivovarov
#DATE: 2016-01-15
#OBJECTIVE: Uploads files from HDFS to s3 object store

# Script copies files from hdfs folders to s3 object store.
# Follow the prompt's questions.
# If you'd like to run script with input parameters use --help to see available options:
# ./hdfs2s3.py -h
import os, sys, subprocess, re, argparse, json


prompt = '> '


def exec_shell(command, printOnly = ""):

   try:

        print("Execute shell command:\n" + command )

        if not ("print" in printOnly.lower()):

            process = subprocess.Popen('/bin/bash', stdin=subprocess.PIPE, stdout=subprocess.PIPE)

            out, err =  process.communicate(command)

            print("Exec Stdout: ", out,"\nExec Error:",err,"\n")

            return out, err

        print("It's just a printed out example of expected command to be executed.")

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


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument("--hdfs_root_dir", help="hdfs_root_dir is a HDFS root source folder", default="")

    parser.add_argument("--s3_dest_path", help="s3_dest_path is a s3 destination path", default="")

    parser.add_argument("--s3_access_key", help="s3_access_key is an amazon account idenifier used to connect to S3 Bucket", default="")

    parser.add_argument("--s3_secret_key", help="hdfs_root_dir is a kind of password for s3_access_key", default="")

    parser.add_argument("--distcp_writing_option", help="distcp_writing_option is a hadoop distcp update/overwrite option", default="")

    parser.add_argument("--print_only", help="print_only is a option to specifiy just print out or execute actual command", default="")

    args = parser.parse_args()

    print("Number of input arguments is: ", len(sys.argv),"\nGiven arguments are: ", json.dumps(vars(args), indent = 4))

    hdfs_root_dir, s3_dest_path, s3_access_key, s3_secret_key, distcp_writing_option, print_only = \
        args.hdfs_root_dir, args.s3_dest_path, args.s3_access_key, args.s3_secret_key, args.distcp_writing_option, args.print_only

    try:

        if len(hdfs_root_dir) == 0 and len(s3_dest_path) == 0:

            print("hadoop distcp will be applying for each subfloder starting from the root folder you specified. \nPlease answer questions below.")

            hdfs_root_dir = raw_input("Enter source HDFS root folder:\n" + prompt)

            s3_dest_path = raw_input("Enter s3 destination root path without last slash :\n" + prompt)

            s3_access_key = raw_input("(Optional, just enter to ignore.) Enter s3 access_key:\n" + prompt)

            s3_secret_key = raw_input("(Optional, just enter to ignore.) Enter s3 secret key:\n" + prompt)

            distcp_writing_option = raw_input("(Optional, just enter to ignore.) Enter s3 writing option - update/overwrite:\n" + prompt)

            print_only = raw_input("(Optional, just enter to execute.) Would you like to execute commands or just print them out? - execute/print:\n" + prompt)

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

        lines = [lines for lines in out.splitlines(True) if re.match(r'^d',lines)]

        if len(lines)>0:

           for line in lines:

                print("Starting copy hdfs folder: " +  line.rsplit('/')[-1].rstrip('\n'))

                if len(distcp_writing_option) > 0:

                    distcp_command=cmd + "/"+line.rsplit('/')[-1].rstrip('\n') +" "+ s3_dest_path +"/"+ line.rsplit('/')[-1].rstrip('\n')+"/"

                else:

                    distcp_command=cmd + "/"+line.rsplit('/')[-1].rstrip('\n') +" "+ s3_dest_path

                exec_shell(distcp_command,print_only)
        else:

            distcp_command = cmd +  " " + s3_dest_path if len(distcp_writing_option) == 0 else cmd +  " " + s3_dest_path +"/" + hdfs_root_dir.rsplit('/')[-1].rstrip('\n')

            exec_shell(distcp_command, print_only)

        print("Process done.")

    except Usage, err:

        print >>sys.stderr, err.msg

        print >>sys.stderr, "for help use --help"

        return 2


if __name__ == "__main__":

    sys.exit(main())
