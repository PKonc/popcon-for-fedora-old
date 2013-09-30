#!/bin/sh

BASEDIR=/srv/popcon.debian.org/popcon-mail
MAILDIR=../Mail
WEBDIR=../www
LOGDIR=$BASEDIR/../logs
BINDIR=$BASEDIR/../bin
DATADIR=$BASEDIR/popcon-entries
SUMMARYDIR=$BASEDIR/all-popcon-results
SUMMARYDIRSTABLE=$BASEDIR/all-popcon-results.stable

# set to 'true' if email submissions should be processed
READMAIL=true

# Remove entries older than # number of days
DAYLIMIT=20

set -e
cd $BASEDIR
umask 0002

# rotate incoming mail spool files
if [ true = "$READMAIL" ] ; then
    mv $MAILDIR/survey new-popcon-entries
    touch $MAILDIR/survey
    chmod go-rwx $MAILDIR/survey

    # process entries, splitting them into individual reports
    rm -fr popcon-gpg
    mkdir popcon-gpg
    $BINDIR/prepop.pl <new-popcon-entries >$LOGDIR/prepop.out 2>&1
    #decrypt reports (to be parallelized)
    find popcon-gpg -type f -name '*.gpg' -execdir gpg {} \;
    #process decrypted reports
    find popcon-gpg -type f -name '*.txt'| xargs cat | $BINDIR/prepop.pl
fi

# delete outdated entries
rm -f results results.stable
find $DATADIR -type f -mtime +$DAYLIMIT -print0 | xargs -0 rm -f --

# Generate statistics
find $DATADIR -type f | xargs cat \
        | nice -15 $BINDIR/popanal.py >$LOGDIR/popanal.out 2>&1
cp results $WEBDIR/all-popcon-results
cp results.stable $WEBDIR/stable/stable-popcon-results
gzip -f $WEBDIR/all-popcon-results
gzip -f $WEBDIR/stable/stable-popcon-results
cp $WEBDIR/all-popcon-results.gz $SUMMARYDIR/popcon-`date +"%Y-%m-%d"`.gz
cp $WEBDIR/stable/stable-popcon-results.gz $SUMMARYDIRSTABLE/popcon-`date +"%Y-%m-%d"`.stable.gz

cd ../popcon-stat
find $SUMMARYDIR -type f -print | sort | $BINDIR/popcon-stat.pl ../www/stat>$LOGDIR/popstat.log 2>&1 
find $SUMMARYDIRSTABLE -type f -print | sort | $BINDIR/popcon-stat.pl ../www/stable/stat >> $LOGDIR/popstat.log 2>&1 

cd ../popcon-web
$BINDIR/popcon.pl >$LOGDIR/popcon.log 2>$LOGDIR/popcon.errors
