#!/usr/bin/env perl

use strict;

my $usage = "\$ slurmjobs.pl <user>";

my $user = shift @ARGV;

if ($user eq '-h' || $user eq '--help'){
	print $usage . "\n";
	exit;
}elsif($user eq ''){
	$user = `whoami`;
	chomp $user;
}

my @jobs = get_jobs($user);
my $command = "sstat --format='JobID,MaxVMSize,MaxRSS,MaxVMSizeNode,MaxRSSNode,MaxVMSizeTask,MaxRSSTask,MinCPU'";
$command .=  " -j " . join(",", @jobs);
system($command);

# Get jobs
sub get_jobs{
	my ($user) = @_;
	my $squeue = `squeue -u $user | grep $user | awk '{print \$1}'`;
	my @jobs = split(/\n/, $squeue);

	return @jobs
}

