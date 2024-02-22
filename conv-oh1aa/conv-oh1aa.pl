# convert oh1aa log format to ADIF
#
# 2024-02-22 DJ5CW
# 
# caveat: there appears to be only one comment field, not separate fields for
# name/qth. all this is dumped into the ADIF "comment" field.
# 
# Some QSOs have missing RSTs. These are replaced by 599.
#
# Special characters are converted/transliterated to ASCII from CP437.

use warnings;
use strict;
use Text::Iconv;

my $converter = Text::Iconv->new("cp437", "ascii//TRANSLIT");

my $line = <>;


print "Converted from $ARGV\n<eoh>\n";

# 9306271135DL/ON4WW/M  539559 14 MHzCW  Mark/100 km/h                         3
# 0     6   10          22 25 28     35  39
while (length($line) >= 78) {
    my $qso = substr($line, 0, 78);
    $line = substr($line, 78,);
    print STDERR "$qso\n";
	my $date = "19".substr($qso, 0, 6);
	my $utc  = substr($qso, 6, 4);
	my $call  = substr($qso, 10, 12);
    $call =~ s/\s+$//g;
	my $rsts  = substr($qso, 22, 3);
    $rsts =~ s/\s+$//g;
	my $rstr  = substr($qso, 25, 3);
    $rstr =~ s/\s+$//g;
	my $freq  = substr($qso, 28, 3);
    $freq =~ s/\s+//g;
	my $mode  = substr($qso, 35, 4);
    $mode =~ s/\s+//g;
	my $rem   = substr($qso, 39, 38);
    $rem =~ s/\s+$//g;
    $rem = $converter->convert($rem);

    if ($call) {
        print a("qso_date", $date);
        print a("time_on", $utc);
        print a("call", $call);
        if (length($rsts) == 0) { $rsts = "599"; }
        if (length($rstr) == 0) { $rstr = "599"; }
        print a("rst_sent", $rsts);
        print a("rst_rcvd", $rstr);
        print a("freq", $freq);
        print a("mode", $mode);
        if (length($rem)) {
            print a("comment", $rem);
        }
        print " <eor>\n";
    }
    

}

sub a {
	($a, $b) = @_;
	return "<$a:".length($b).">$b ";
}
