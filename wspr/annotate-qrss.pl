#!/usr/bin/perl -w

system("sleep 10");

use strict;
use warnings;

#convert 30m.png  -pointsize 12 -fill white -annotate +130+100 'SO5CW' 30m-a.png

# offsets start in the top left corner of the image

# x offset for first WSPR 2 minute slot
my $x0 = 92;
# x width of a 2 min slot
my $wx = 175/2;

# y offset for 10140.2 kHz
my $y0 = 215;
# y Pixel/Hz scale
my $ys = 1.4;

chdir("/home/fabian/grabs");

my $filename = "30m.png";
$filename =~ /(.*).png$/;
my $basename = $1;

my $data = `tail -n300 ~/wsprcan/ALL_WSPR.TXT`;
my @d = split(/\n/, $data);
@d = reverse(@d);

my $cnt = 0;

`cp $filename $basename-0.png`;

my $min10_start = -1;

my $annotations = "";

# assemble string with annotations 

# example input line:
# 240810 1502   4 -23 -2.2 10.1401428  DJ2TS JO40 30           0     1    0

my @gmt = gmtime();  # when we process the above (1500-1508 slots, it is 1510)
my $time_filter = sprintf("%02d%02d", $gmt[2], $gmt[1] - 10);    # 1500
$time_filter =~ s/\d$//g;    # 150

foreach my $line (@d) {
    my @a = split(/\s+/, $line);
    my $slot = substr($a[1], 3, 1);    # 0, 2, 4, 6, 8 ...
    my $min10 = substr($a[1], 0, 3);   # 150
    my $freq = $a[5]*1000000;
    my $call = $a[6]." (".$a[3]." dB)";

    if ($min10 ne $time_filter) {
        last;
    }

    # don't print decodes above 10.140275 because they are out of the spectrum
    # display
    if ($freq > 10140275) {
        next;
    }

    my $xpos = 4 + $x0 + $wx * $slot;
    my $ypos = $y0 - $ys * ($freq - 10140200) - 5;

    $annotations .= " -annotate +$xpos+$ypos '$call'  ";

}


my $cmd = "convert $basename-0.png -pointsize 12 -fill white $annotations $filename";

#print " cmd line: $cmd ";

`$cmd`;

`scp $filename fabian\@d.fkurz.net:/home/fabian/sites/fkurz.net/ham/qrss`



