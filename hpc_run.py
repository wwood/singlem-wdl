#!/usr/bin/env python3

__author__ = "Ben Woodcroft"
__copyright__ = "Copyright 2021"
__credits__ = ["Ben Woodcroft"]
__license__ = "GPL3+"
__maintainer__ = "Ben Woodcroft"
__email__ = "b.woodcroft near qut.edu.au"
__status__ = "Development"

import argparse
import logging
import os

import extern


if __name__ == '__main__':
    parser= argparse.ArgumentParser(
        description='Download and run singlem through the microbiome queue a singlem SRA run')
    parser.add_argument(
        'run',
        help='Run number to download e.g. ERR1739691',
        required=True)
    parser.add_argument(
        'working_dorectory',
        help='Where to run the analysis (folder will be created)',
        required=True)
    parser.add_argument(
        'download_threads',
        help='Threads to provide the "sem" command, to limit download count',
        required=True)

    parser.add_argument('--debug', help='output debug information',
                        action="store_true", default=False)
    parser.add_argument('--quiet', help='only output errors',
                        action="store_true", default=False)
    args= parser.parse_args()

    if args.debug:
        loglevel= logging.DEBUG
    elif args.quiet:
        loglevel= logging.ERROR
    else:
        loglevel= logging.INFO
    logging.basicConfig(
        level=loglevel, format='%(asctime)s %(levelname)s: %(message)s',
        datefmt='%m/%d/%Y %I:%M:%S %p')


    # Take as input 1 run identifier and a folder to run in
    working_directory = args.working_directory
    os.makedirs(working_directory, exist_ok=True)
    os.chdir(working_directory)
    sem_command = "sem -j {} {} ssh transfer1 'cd {} && source activate " \
        "~/git/singlem-wdl/hpc/ena-fast-download-env && " \
        "~/git/singlem-wdl/hpc/ena-fast-download/ncbi-download.py --download-method prefetch {}'".format(
            args.download_threads, args.download_semaphore, working_directory, args.run
    )
    extern.run(sem_command)

    fastqs = list([f for f in os.listdir('.') if f.endswith('.fastq')])

    if len(fastqs) == 3:
        raise Exception("Found 3 output files for {}".format(args.run))
    elif len(fastqs) == 2:
        fastqs = list(sorted(fastqs))
        reverse_args = "--reverse {}".format(fastqs[1])
    else:
        reverse_args = ""

    singlem_command = "/work2/microbiome/sw/hpc_scripts/bin/mqsub --hours 12 -t 2 -- " \
        "time ~/git/singlem-wdl/hpc/singlem/bin/singlem pipe " \
        "--forward {} "\
            "{}"\
        "--archive_otu_table {}.singlem.json --threads 2 --diamond-package-assignment --assignment-method diamond "\
        "--min_orf_length 72 "\
        "--singlem-packages `ls -d ~/git/singlem-wdl/spkg_picked_chainsaw20210225.smaller/*spkg` "\
        "--working-directory-tmpdir".format(
            fastqs[0],
            reverse_args,
            args.run
        )
    extern.run(singlem_command)