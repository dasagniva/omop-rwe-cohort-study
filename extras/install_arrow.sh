#!/bin/bash
exec > /tmp/arrow_install.log 2>&1
rm -rf ~/R/library/00LOCK-arrow
Rscript --no-save -e "
user_lib <- path.expand('~/R/library')
.libPaths(c(user_lib, .libPaths()))
install.packages('arrow', lib=user_lib,
  repos='https://packagemanager.posit.co/cran/__linux__/noble/latest',
  quiet=FALSE)
cat('arrow:', 'arrow' %in% installed.packages()[,'Package'], '\n')
"
