# db/*
ls -rt db/* | head -n -50 | while read fname_to_del; do rm -f ${fname_to_del} 2>&1 >/dev/null ; done

# tmp/*
ls -rt tmp/* | head -n -50 | while read fname_to_del; do rm -f ${fname_to_del} 2>&1 >/dev/null ; done

# log/*
ls -rt log/* | head -n -10 | while read fname_to_del; do rm -f ${fname_to_del} 2>&1 >/dev/null ; done
ls -s log/* db/* tmp/* | awk '{if($1 > 1024) print $2}' | while read fname_to_trunc; do echo "`date` TRUNC" > ${fname_to_trunc} 2>/dev/null; done
