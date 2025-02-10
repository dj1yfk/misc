#!/usr/bin/perl -w

use strict;
use JSON::PP;
use Time::Piece;
use GD;
use GD::Polyline;

system("rm -f xrays-1-day.*");
system("wget --header=\"accept-encoding: gzip\" https://services.swpc.noaa.gov/json/goes/primary/xrays-1-day.json -O xrays-1-day.json.gz");
system("gunzip xrays-1-day.json.gz");

my $json = `cat xrays-1-day.json`;

my $data = decode_json($json);

my @fluxx;

foreach my $d (@{$data}) {
    my $t = $d->{time_tag};
    my $flux = $d->{flux};
    my $e = $d->{energy};

    $t =~ s/Z//g;

    my $ts = Time::Piece->strptime($t, '%Y-%m-%dT%H:%M:%S')->epoch;

    if ($e eq "0.1-0.8nm") {
        #        print "$t ($ts) => $flux\n";
        push @fluxx, $flux;
    }
}

# 10 minute frames:
# width = 1162 x 813
# start of time x axis @ pixel 92, 10 minutes = 878 pixel

my $im = GD::Image->new(1162, 105);
my $white = $im->colorAllocate(255,255,255);
my $gray= $im->colorAllocate(100,100,100);
my $black = $im->colorAllocate(0,0,0);
$im->fill(1,1,$black);

$im->line(92, 10, 92, 100, $gray);
$im->line(970, 10, 970, 100, $gray);
$im->line(92, 10, (92+878), 10, $gray);
$im->line(92, 40, (92+878), 40, $gray);
$im->line(92, 70, (92+878), 70, $gray);
$im->line(92, 100, (92+878), 100, $gray);

$im->stringUp(gdLargeFont,10,90,"Solar Flux",$white);
$im->stringUp(gdLargeFont,28,90,"GEOS-16",$white);
$im->string(gdGiantFont,70,18,"X",$white);
$im->string(gdGiantFont,70,48,"M",$white);
$im->string(gdGiantFont,70,78,"C",$white);

# draw polyline of 10 most recent datapoints

my @data = qw/1e-6 2e-6 3e-6 9e-6 1e-5 2e-6 2.5e-6 2.9e-6 3e-6 2.5e-6/;

my $polyline = GD::Polyline->new;
for (0..9) {
    my $yval = 10*log($data[$_])/log(10) - 10*log(1e-6)/log(10);
    $yval *= 3;
    print "val $data[$_] -> $yval\n";
    $polyline->addPt(92 + $_*878/10, 100-$yval);
}
$im->polydraw($polyline,$white);

# 24h view
# width = 1640 x 813
# start of time x axis @ pixel 93, 24h  pixel

$im = GD::Image->new(1640, 105);
$white = $im->colorAllocate(255,255,255);
$gray= $im->colorAllocate(100,100,100);
$black = $im->colorAllocate(0,0,0);
$im->fill(1,1,$black);
$im->line(93, 10, 93, 100, $gray);
$im->line(1532, 10, 1532, 100, $gray);
$im->line(93, 10, 1532, 10, $gray);
$im->line(93, 40, 1532, 40, $gray);
$im->line(93, 70, 1532, 70, $gray);
$im->line(93, 100, 1532, 100, $gray);

$im->stringUp(gdLargeFont,10,90,"Solar Flux",$white);
$im->stringUp(gdLargeFont,28,90,"GEOS-16",$white);
$im->string(gdGiantFont,70,18,"X",$white);
$im->string(gdGiantFont,70,48,"M",$white);
$im->string(gdGiantFont,70,78,"C",$white);

# draw polyline of 10 most recent datapoints

my @data = qw/1e-6 2e-6 3e-6 9e-6 1e-5 2e-6 2.5e-6 2.9e-6 3e-6 2.5e-6/;

my $polyline = GD::Polyline->new;
for (0..1437) {
    if ($fluxx[$_] == 0) {
        $fluxx[$_] = 1e-6;
    }
    my $yval = 10*log($fluxx[$_])/log(10) - 10*log(1e-6)/log(10);
    $yval *= 3;
    #    print "val $data[$_] -> $yval\n";
    $polyline->addPt(93 + $_, 100-$yval);
}
$im->polydraw($polyline,$white);




open OUT, ">fluxplot.png";
binmode OUT;
print OUT $im->png;
close OUT;







