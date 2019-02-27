#!/usr/bin/env python

import os
import errno
import subprocess
import sys
import re

TMPDIR='.gitbranchtrack'

try:
    os.makedirs(TMPDIR)
except OSError as err:
    if err.errno != errno.EEXIST:
        raise

search_branches = os.environ['KERNEL_BRANCHES'].split()
remote_branches = subprocess.check_output("git branch -r", shell=True).split()

build = False
branch_name = ''
for sb in search_branches:
    if (build):
        break

    rex = re.compile("origin/(?P<branch_name>%s)" % sb)
    for rb in remote_branches:
        s = rex.search(rb)
        if s:
            last_revision = subprocess.check_output('git rev-parse %s' % rb, shell=True).strip()

            branch_name = s.group('branch_name')
            file_name = os.path.join(TMPDIR, re.sub("[^A-Za-z0-9._-]", "_", branch_name))
            revisions = []
            try:
                f = open(file_name, 'r')
                revisions = f.read().split()
            except IOError as err:
                if err.errno != errno.ENOENT:
                    raise

            if last_revision not in revisions:
                with open(file_name, 'a+') as f:
                    f.write("%s\n" % last_revision)

                build = True
                break

if build:
    print("KERNEL_BRANCH=%s" % branch_name)
    sys.exit(0)

sys.exit(1)