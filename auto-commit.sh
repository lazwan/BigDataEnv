#!/bin/sh
git add .
git commit -m "auto-commit.sh: `date +%x\ %X`"
git --no-pager log -n 1
