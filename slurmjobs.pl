#!/usr/bin/env perl
# Copyright (C) 2018 Sur Herrera Paredes

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


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

