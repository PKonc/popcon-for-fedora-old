#! /usr/bin/perl -wT

my $mirrorbase = "/srv/mirrors/debian";
my $docurlbase = "";

$ENV{PATH}="/bin:/usr/bin";

for (glob("$mirrorbase/dists/stable/*/binary-*/Packages.gz"))
{
  /([^[:space:]]+)/ or die("incorrect package name");
  $file = $1;#Untaint
  open AVAIL, "-|:encoding(UTF-8)","zcat $file";
  while(<AVAIL>)
  {
/^Package: (.+)/  and do {$p=$1;next;};
/^Section: (.+)/ or next;
          $section{$p}=$1;
  }
  close AVAIL;
}
@pkgs=sort keys %section;
for (@pkgs)
{
  print "$_ $section{$_}\n";
}
