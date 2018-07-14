#!/usr/bin/env python
#.git/hooks/post-commit
from subprocess import check_output

commitmsg = check_output(["git", "log", "-1"])
print(commitmsg)
print(len(commitmsg))

