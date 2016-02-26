#!/usr/bin/python
from __future__ import print_function

#  TITLE: distcp
#  AUTHORS: Alexey Kuksin, Elena Mishkina, Alex Pivovarov
#  DATE: 2016-01-15
#  OBJECTIVE: Wraper for "hadoop distcp" for given folder list. E.g. Uploads files from HDFS to s3 object store.
#  distcp.py script splits source root directory to make a separate hadoop distcp command run for each sub folder.
#  Follow the prompt's questions.
#  If you'd like to run script with input parameters use --help to see available options:
# ./distcp.py -h


import os, sys, subprocess, re, argparse, json


prompt = '> '


def prog_quit(error_msg):
    print("Program terminated due: ", error_msg)
    quit()


def add_cmd(cmd, args):
    try:
        if args.preserve: cmd = cmd + " -p " + args.preserve + " "
        if args.num_maps: cmd = cmd + " -m " + args.num_maps + " "
        if args.filelimit: cmd = cmd + " -filelimit " + args.filelimit + " "
        if args.update and args.overwrite:
            cmd = cmd + " -overwrite "
        elif args.update and not args.overwrite:
            cmd = cmd + " -update "
        elif not args.update and args.overwrite:
            cmd = cmd + " -overwrite "
        if args.ignore_failures: cmd = cmd + " -i "
        if args.logdir: cmd = cmd + " -log " + args.logdir + " "
        if args.sizelimit: cmd = cmd + " -sizelimit " + args.sizelimit + " "
        if args.delete: cmd = cmd + " -delete "
        return cmd
    except:
        e = sys.exc_info()
        print("Command line construction failed: ", e)
        sys.exit(-1)


def exec_shell(command, print_only = False, call_type="pipe", shell=True):
   try:
        print("Execute shell command:\n" + command + "\nIt's just a printed out example of expected command to be executed." \
                  if print_only else command)
        if not(print_only):
            if "pipe" in call_type:
                process = subprocess.Popen('/bin/bash', stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=shell)
                out, err =  process.communicate(command)
                exit_code = process.returncode
                print("Exec stdout: ", out,"\nExec error: ",err,"\nExit code: ",exit_code)
                return out, err, exit_code
            else:
                exit_code = subprocess.call(command, shell=shell)
                print("Exit Code: ",exit_code)
                return None, None, exit_code
   except:
        e = sys.exc_info()
        print("exec_shell failed: ", e)
        ret = raw_input("Would you like to continue?\n" + prompt)
        if re.match(ret, 'yes', re.IGNORECASE):
            return None,None,-1
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
    parser = argparse.ArgumentParser(description= """          This is a wrapper for hadoop distcp.
    to backup large subfolder tree list. E.g. Uploads files from HDFS to s3 object store.
    script wraps "hadoop distcp", reads source directory to make a separate call for each sub-folder.""",
    usage='%(prog)s [OPTIONS]',
    formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument("files", nargs="*", help="""     The most common usage of distcp.py is:
    bash$ ./distcp.py hdfs://nn1:8020/foo/bar \\
                    hdfs://nn2:8020/bar/foo
    This will expand the namespace under /foo/bar on nn1 into a temporary file, partition its contents among
    a set of map tasks, and start a copy on each TaskTracker from nn1 to nn2. Note that DistCp expects absolute paths.
    One can also specify multiple source directories on the command line:
    bash$ ./distcp.py hdfs://nn1:8020/foo/a \\
                      hdfs://nn1:8020/foo/b \\
                      hdfs://nn2:8020/bar/foo
    Or, equivalently, from a file using the -f option:
    bash$ ./distcp.py -f hdfs://nn1:8020/srclist \\
                         hdfs://nn2:8020/bar/foo
    Where srclist contains
        hdfs://nn1:8020/foo/a \\
        hdfs://nn1:8020/foo/b""")

    parser.add_argument("-p",dest="preserve", metavar="[rbugp]",choices="rbugp",
                    help="""Preserve description:
        r: replication number
        b: block size
        u: user
        g: group
        p: permission
    Note:
        Modification times are not preserved.
        Also, when -update is specified, status updates will not be synchronized
        unless the file sizes also differ (i.e. unless the file is re-created).
        """)

    parser.add_argument("-i",dest="ignore_failures", action='store_true',
    help="""Ignore failures option will keep more accurate statistics about the copy than the default case.
    It also preserves logs from failed copies, which can be valuable for debugging.
    Finally, a failing map will not cause the job to fail before all splits are attempted.
    """)

    parser.add_argument("-log",dest="logdir", nargs="?", metavar="<logdir>",
    help="""Write logs to <logdir>. DistCp keeps logs of each file it attempts to copy as map output.
    If a map fails, the log output will not be retained if it is re-executed.
    """)

    parser.add_argument("-m",dest="num_maps", nargs="?", metavar="<num_maps>",
    help="""Maximum number of simultaneous copies. Specify the number of maps to copy data.
    Note that more maps may not necessarily improve throughput.
    """)

    parser.add_argument("-overwrite",dest="overwrite", action='store_true',
    help="""Overwrites destination. If a map fails and -i is not specified, all the files in the split,
    not only those that failed, will be recopied. As discussed in the following, it also changes the semantics for
    generating destination paths, so users should use this carefully.
    """)

    parser.add_argument("-update",dest="update", action='store_true',
    help="""Overwrite if src size different from dst size. As noted in the preceding, this is not a "sync" operation.
    If the source and destination file sizes is differ, the source file replaces the destination file.
    """)

    parser.add_argument("-f",dest="urilist", nargs="?", metavar="URILIST",
    help="""This is equivalent to listing each source on the command line.
    The urilist_uri list should be a fully qualified URI.
    """)

    parser.add_argument("-filelimit",dest="filelimit", nargs="?", metavar="<n>",
    help="Limit the total number of files to be <= n")

    parser.add_argument("-sizelimit",dest="sizelimit", nargs="?", metavar="<n>",
    help="Limit the total size to be <= n bytes, can be specified with symbolic representation like 1230k or 891g")

    parser.add_argument("-delete",dest="delete", action='store_true',
    help="Delete the files existing in the dst but not in src")

    parser.add_argument("-print", dest="print", action='store_true', help="Specifies to print only of an actual commands to be executed.")

    args = parser.parse_args()

    print("Number of expected arguments is: ",len(vars(args)))

    print("Number of input arguments is: ", len(sys.argv),"\nGiven arguments are: ", json.dumps(vars(args), indent = 4))

    try:
        if len(sys.argv) == 1:
            print("hadoop distcp will be applying for each subfloder starting from the root folder you specified. \nPlease answer questions below.")
            args.files = []
            args.files.append(raw_input("Enter uri path to your source folders:\n" + prompt))
            args.files.append(raw_input("Enter destination uri path :\n" + prompt))
            print("(Optional. Enter to ignore.) Enter writing option - update/overwrite:\n")
            writing_option = ["ignore","update","overwrite"]
            choice = raw_input("(Optional. Enter to ignore.) Choose writing option:\n"" " + \
                               ",".join([str(a) + ":" + b for a, b in enumerate(writing_option)])+" ? >")

            print(type(choice),choice)

            if writing_option[int(0 if choice== "" else choice)] == "overwrite":
                args.overwrite = True

            if writing_option[int(0 if choice== "" else choice)] == "update":
                args.update = True

            writing_option = ["ignore","delete"]

            choice = raw_input("(Optional. Enter to ignore.) Choose 1 to delete the files existing in the dst but not in src:\n"" " + \
                               ",".join([str(a) + ":" + b for a, b in enumerate(writing_option)])+" ? >")

            if writing_option[int(0 if choice== "" else choice)] == "delete":
                args.delete = True

            writing_option = ["ignore","print"]

            choice = raw_input("(Optional. Enter to ignore.) Choose 1 to print out genereated command only:\n"" " + \
                               ",".join([str(a) + ":" + b for a, b in enumerate(writing_option)])+" ? >")

            if writing_option[int(0 if choice== "" else choice)] == "print":
                args.print = True

            print("Number of expected arguments is: ",len(vars(args)))

            print("Number of input arguments is: ", len(sys.argv),"\nGiven arguments are: ", json.dumps(vars(args), indent = 4))

        if len(args.files) > 0:
            dst_uri = args.files[-1]
            add_cmd("hadoop distcp", args)

        print("args.urilist: ",args.urilist)

        if args.urilist:
            out, err, exit_code = exec_shell("hadoop fs -cat " + args.urilist)
            if exit_code <> 0:
                prog_quit("wrong uri. Use [hdfs:///] instead of [hdfs://]" if "Usage: hadoop fs [generic options] -cat [-ignoreCrc] <src>" in err else "urilist validation failure")
            uris = [f for f in out.split(os.linesep) if len(f)>0]
        elif len(args.files)>0:
            uris = args.files[:-1]
        else:
            prog_quit("There is no source specified")

        for src_uri in uris:
            def evaluate_uri(src_uri , uri, dst_uri, uri_type):
                    #print("evaluate_uri:\nsrc_uri: ",src_uri,"\nuri: ",uri,"\ndst_uri: ",dst_uri,"\nuri_type: ",uri_type)
                    return src_uri + "/" + uri.split("/")[-1] + " " + dst_uri + "/" + uri.split("/")[-1]  \
                        if uri_type else uri + " " + dst_uri + "/" + uri.split("/")[-1]
            out, err, exit_code = exec_shell("hadoop fs -ls  " + src_uri)

            if exit_code == 0:
                dir_list = dict([(line.split(chr(32))[-1].rstrip('\n'),True if re.match('^d',line) else False) \
                                 for line in out.splitlines(True) if len(line.split(chr(32)))>3])
                if len(dir_list) > 0:
                    for uri, uri_type  in dir_list.iteritems():
                        exec_shell(add_cmd("hadoop distcp", args) + " " + evaluate_uri(src_uri , uri, dst_uri, uri_type),args.print )

        print("Process done.")

    except Usage, err:
        print >>sys.stderr, err.msg
        print >>sys.stderr, "for help use --help"
        return 2


if __name__ == "__main__":
    sys.exit(main())
