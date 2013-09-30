#!/usr/bin/perl -wT
# Accept popularity-contest entries on stdin and drop them into a
# subdirectory with a name based on their MD5 ID.
#
# Only the most recent entry with a given MD5 ID is kept.
#

$dirname = 'popcon-entries';
$gpgdir = 'popcon-gpg';
$now = time;
$filenum=0;

sub get_report
{
  my($id,$file,$mtime,$vers);
  my $line=$_;
  chomp $line;
  my @line=split(/ +/, $line);
  my %field;
  for (@line)
  {
    my ($key, $value) = split(':', $_, 2);
    $field{$key}=$value;
  };
  $id=$field{'ID'};
  if (!defined($id) || $id !~ /^([a-f0-9]{32})$/)
  {
    print STDERR "Bad hostid: $id\n";
    return 'reject';
  }
  $id=$1; #untaint $id
  $vers=$field{'POPCONVER'};
  if (defined($vers) && $vers =~ /^1\.56ubuntu1/)
  {
    print STDERR "Report rejected: $vers: $id\n";
    return 'reject';
  }
  $mtime=$field{'TIME'};
  if (!defined($mtime) || $mtime!~/^([0-9]+)$/)
  {
    print STDERR "Bad mtime $mtime\n";
    return 'reject';
  }
  $mtime=int $1; #untaint $mtime;
  $mtime=$now if ($mtime > $now);
  my $dir=substr($id,0,2);
  unless (-d "$dirname/$dir") {
    mkdir("$dirname/$dir",0755) or return 'reject';
  }
  $file="$dirname/$dir/$id";
  open REPORT, ">",$file or return 'reject';
  print REPORT $_;
  while(<>)
  {
    /^From/ and last;
    print REPORT $_; #accept line.
    /^END-POPULARITY-CONTEST-0/ and do
    {
      close REPORT;
      utime $mtime, $mtime, $file;
      return 'accept';
    };
  }
  close REPORT;
  unlink $file;
  print STDERR "Bad report $file\n";
  return 'reject';
}

sub get_gpg
{
  my $file="$gpgdir/$filenum.txt.gpg";
  $filenum++;
  open REPORT, ">",$file or return 'reject';
  print REPORT $_;
  while(<>)
  {
    /^From/ and last;
    print REPORT $_; #accept line.
    /^-----END PGP MESSAGE-----/ and do
    {
      close REPORT;
      return 'accept';
    };
  }
  close REPORT;
  unlink $file;
  print STDERR "Bad report $file\n";
  return 'reject';
}

while(<>)
{
    /^POPULARITY-CONTEST-0/ and get_report();
    /^-----BEGIN PGP MESSAGE-----/ and get_gpg();
}
