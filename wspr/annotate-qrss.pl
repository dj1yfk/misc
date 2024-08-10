#!/usr/bin/perl -w

# annotates a QrssPiG output picture with received WSPR signals from k9an-wsprd
# see: https://fkurz.net/ham/qrss/qrss-wsprd-setup.html

use strict;
use warnings;

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

# Fetch latest spots...
#my $data = `curl "https://db1.wspr.live/?query=SELECT%20time,%20frequency,%20tx_sign,%20tx_loc,%20distance,%20power,%20snr%20FROM%20wspr.rx%20where%20match(rx_sign,%27^SO5CW%27)%20and%20time%20%3E%20subtractMinutes(now(),%2013)%20order%20by%20time%20desc%20limit%2010%20FORMAT%20CSV"`;

my $data = `tail -n50 ~/wsprcan/ALL_WSPR.TXT`;
my @d = split(/\n/, $data);
@d = reverse(@d);

my $cnt = 0;

`cp $filename $basename-0.png`;

my $min10_start = -1;

foreach my $line (@d) {
    # 240810 1502   4 -23 -2.2 10.1401428  DJ2TS JO40 30           0     1    0
    $cnt++;
    my $oc = $cnt - 1;
    my @a = split(/\s+/, $line);
    my $slot = substr($a[1], 3, 1);    # 0, 2, 4, 6, 8 ...
    my $min10 = substr($a[1], 2, 1);
    my $freq = $a[5]*1000000;
    my $call = $a[6]." (".$a[3]." dB)";

    if ($min10_start == -1) {
        $min10_start = $min10;
    }

    if ($min10 != $min10_start) {
        $cnt--;
        last;
    }

    my $xpos = 4 + $x0 + $wx * $slot;
    my $ypos = $y0 - $ys * ($freq - 10140200) - 5;
    #    print $line."\n";

    `convert $basename-$oc.png -pointsize 12 -fill white -annotate +$xpos+$ypos '$call' $basename-$cnt.png`;
    `rm -f $basename-$oc.png`;

}
`cp $basename-$cnt.png $filename`;
`scp $filename fabian\@d.fkurz.net:/home/fabian/sites/fkurz.net/ham/qrss`



