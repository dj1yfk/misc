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


# add this 10 minute slice to the 24h display *before* we add the WSPR overlay
# the 24h display is 1440 pixels wide (10 per 10 min slice) and 680px high
# we move everything 10 pixels to the left and add the latest slice at the end

system("convert -crop 875x680+93+106 $filename cropped.png");   # cut out area of interest
system("mogrify -resize 10x680\! cropped.png");                 # smash to 10px width

# make sure 24h pic is on RAM disk. If not (e.g. due to an unplanned reboot),
# download latest from the web and cut out the relevant part
unless (-f "24h.png") {
    #system("wget https://fkurz.net/ham/qrss/30m-24h-view.png -O downloaded.png");
    #system("convert -crop 1439x680+93+106 downloaded.png 24h.png");
    system("cp /home/fabian/24h.png /home/fabian/grabs");
}

# remove oldest 10 minutes from 24h pic
system("convert -gravity West -chop 10x0 24h.png 24hcrop.png");
#system("cp 24h.png 24hcrop.png");

# append slice
system("convert 24hcrop.png cropped.png +append 24h.png");

# embed in template 
system("convert ~/30m-24h-template.png 24h.png -geometry +93+106 -composite 30m-24h-view-no-ts.png");

# add time stamps
my @g = gmtime(time);
# how many minutes are we into the current hour?
my $min = $g[1];
# current hour in UTC
my $hr = $g[2];
# pixel 1533 - $min - 60 = start of previous hour - here we will start!
my $ann = "";
my $tmarkx = 1533 - $min - 60;
for (my $i = 0; $i < 23; $i++) {
    if (--$hr < 0) { $hr = 23; }
    $ann .= sprintf(" -annotate +$tmarkx+800 '| %02d:00z' ", $hr);
    $tmarkx -= 60;
}
system("convert 30m-24h-view-no-ts.png -pointsize 12 -fill white $ann 30m-24h-view.png");


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

my @gmt = gmtime(time - 600);  # when we process the above (1500-1508 slots, it is 1510) - so go back 10 mins in time...
my $time_filter = sprintf("%02d%02d", $gmt[2], $gmt[1]);    # 1500
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

    # don't print decodes above 10.140280 because they are out of the spectrum
    # display
    if ($freq > 10140280 + 30) {
        next;
    }

    my $xpos = 4 + $x0 + $wx * $slot;
    my $ypos = $y0 - $ys * ($freq - 30 - 10140200) - 5;

    $annotations .= " -annotate +$xpos+$ypos '$call'  ";

}


my $cmd = "convert $basename-0.png -pointsize 12 -fill white $annotations $filename";

#print " cmd line: $cmd ";

`$cmd`;

`scp $filename fabian\@d.fkurz.net:/home/fabian/sites/fkurz.net/ham/qrss`;

sleep 10;

# upload 24h image once an hour only? - for now, let's do it every 10 mins
#if ($gmt[0] == 0) {
`scp 30m-24h-view.png fabian\@d.fkurz.net:/home/fabian/sites/fkurz.net/ham/qrss/30m-24h-view.png`;
#}


