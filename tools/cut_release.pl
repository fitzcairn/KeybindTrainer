#!/usr/bin/perl -w

use strict;
use File::Find;
use File::Spec;
use File::Spec::Functions;

# List of files to exclude from all releases.
my %exclude = (
               "test_trials.txt" => 1,
               "todo.txt" => 1,
               "CallbackHandler-1.0.lua" => 1,
               "CallbackHandler-1.0.xml" => 1,
               "LibDBIcon-1.0.lua" => 1,
               "LibDataBroker-1.1.lua" => 1,
               "LibStub.lua" => 1,
               "screen.png" => 1,
               "screen_trial.png" => 1,
              );

# Get dev and release roots
die("Usage: $0 <dev root> <release root> [1 for dry run]\n")
  unless defined $ARGV[0] && -d $ARGV[0] && defined $ARGV[1] && -d $ARGV[1];
my $dev_root = File::Spec->rel2abs($ARGV[0]);
my $rel_root = File::Spec->rel2abs($ARGV[1]);
my $dryrun   = $ARGV[2];

# Clean out the release root in prep for release files.
find(\&doclean, ($ARGV[1]));

# Do copy, except for svn files
my $found = 0;
find(\&docopy, ($ARGV[0]));

# Did we do anything?
die("No files found in $ARGV[0].  Try again?\n") unless $found;


#
# Subs
#

sub doclean {
  my $d_dir = catfile($rel_root, $File::Find::dir);
  my $d     = catfile($d_dir, $_);

  # Don't remove svn files.
  return if (-d $d or $d =~ m/\.svn/ or $d =~ m/\.svn/);

  # Do the clean.
  my $cmd = "rm -rf '$d'";
  print($cmd."\n");
  if (!$dryrun) {
    print("   ...executing...\n");
    !system("$cmd") or die("Error cleaning $d: $!");
  }
}

sub docopy {
  my $s     = catfile($dev_root, $File::Find::dir, $_);
  my $d_dir = catfile($rel_root, $File::Find::dir);
  my $d     = catfile($d_dir, $_);

  # Don't copy svn files or files maked as excluded.
  return if (-d $s or $s =~ m/\.svn/ or $s =~ m/\.svn/ or defined($exclude{$_}));
  $found = 1;

  # Do the copy.
  my $cmd1 = "mkdir -p '$d_dir'";
  my $cmd2 = "cp -r '$s' '$d'";
  print($cmd1."\n");
  print($cmd2."\n");
  if (!$dryrun) {
    print("   ...executing...\n");
    !system("$cmd1") || die("Error with $cmd1: $!");
    !system("$cmd2") or die("Error with $cmd2: $!");
  }
}




