#!/usr/bin/perl -w

use strict;
use File::Spec::Functions;

# Get a dir of help files from cmd line arg.
die("Usage: $0 <lua help file dir> <html help file dir>\n")
  unless defined $ARGV[0] && -d $ARGV[0] && defined $ARGV[1] && -d $ARGV[1];

# Loop through files and translate to html.
my ($found, $in, $out, $line);
foreach my $s (glob(catfile($ARGV[0], "Help_*.lua"))) {
  my $d = $s;
  $d =~ s/^.+(Help.+).lua$/$1.html/;
  $d = catfile($ARGV[1], $d);

  open($in, $s)     || die("Error opening $s");
  open($out, ">", "$d") || die("Error opening $d");

  while ($line = readline($in)) {
    next if $line =~ m/\[\[/;
    next if $line =~ m/\]\]/;
    next if $line =~ m/^<br/;
    $line =~ s/cFFFF/cFF00/g;
    $line =~ s/\|cFF(\w{6})/<font color="#$1">/g;
    $line =~ s/\|r/<\/font>/g;
    print $out $line;
  }

  close($in);
  close($out);
  $found = 1;
}

# Did we do anything?
die("No help files found in $ARGV[0].  Try again?\n") unless $found;



