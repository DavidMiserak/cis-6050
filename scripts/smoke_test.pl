#!/usr/bin/env perl

use warnings;

my @files = `cat txt/smoke_test.txt`;
my $i = 0;

foreach my $file (@files) {
	chomp($file);
	$i++;
	print("----- ${i}: ${file} -----\n");
	system("./pascal.exe ${file}");
}
