#!/usr/bin/perl
#
# dat2bin - Convert Intel processor microcode data files to binary format
# -----------------------------------------------------------------------
# By C.Boelitz (c.boelitz@web.de)
# Last edited: 20170818
#
##############################################################################

#use diagnostics;
use strict;
use warnings;

no warnings 'uninitialized';

### SUBS #####################################################################

sub usage
{
  print "Usage: \n";
  print "  dat2bin <input file>\n";
}

sub shuffle_bytes
{
	$b = shift;
	
	return substr($b,6,2) . substr($b,4,2) . substr($b,2,2) . substr($b,0,2)
}


### MAIN #####################################################################

#Header
print "dat2bin.pl 1.0\n\n";

#Cmdline sanity
if (!defined($ARGV[0]))
{
  usage();
  exit(1);
}

my $infile = $ARGV[0];

#input file existent?
if (!-e $infile) { die "$infile non-existent."; }

print "Input file: $infile\n";

#Open input file
open(my $f, "<", $infile) or die "Can't open $infile: $!";

my $of = undef; #Output file handle


while(my $line = <$f>)
{
	my $outfile_name = "";
	
	#Skip empty lines
	next if length($line) < 1;
	
	#Check for microcode begin
	if (  $line =~ /^\/\*\s*(.*)\.inc\s*\*\//  )
	{
		#Close previous output file if any is open
		close($of) if defined($of);

		die ("Found microcode name, but got an error matching its name pattern.") if (length($1) < 1);
		
		$outfile_name = "$1.bin";
		
		print "Exporting to $outfile_name.\n";
		
		
		
		#Open new output file for writing
		open ($of, ">:raw", $outfile_name) or die "Can't open $outfile_name: $!";
		
		#print $line;
	}
	
	#Continue when other comments found
	next if ($line =~ /^\//);
	
	#Read in line of 4x4 bytes
	if (  $line =~ /^0x([a-fA-F0-9]{8})\s*,\s*0x([a-fA-F0-9]{8})\s*,\s*0x([a-fA-F0-9]{8})\s*,\s*0x([a-fA-F0-9]{8})\s*,\s*/  )
	{
		#Shuffle byte order around
		
		my $bytes1 = shuffle_bytes($1);
		my $bytes2 = shuffle_bytes($2);
		my $bytes3 = shuffle_bytes($3);
		my $bytes4 = shuffle_bytes($4);
		
		my $chunk = $bytes1.$bytes2.$bytes3.$bytes4;
		
		my @hex_bytes_line = ( $chunk =~ m/../g );
	
		my $hex_bytes = pack("H2" x 16, @hex_bytes_line); # 16 bytes in one chunk
		
		print $of $hex_bytes;
		
		#print "$hex_bytes\n";
	}
}

#Close last one
close($of) if defined($of);

exit(0);
