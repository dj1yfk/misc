<!DOCTYPE html>

<link rel="stylesheet" type="text/css" href="/fkurz.css">

<?php
$files = glob("archive/30m-*.png");
$files = array_slice($files, -144);
?>


<h1>SO5CW QRSS / WSPR grabber - 24h graph</h1>

<map name="30m">

<?php
    for ($i = 0; $i < 144; $i++) {
        echo "<area shape='rect' coords='".(93 + $i*10).",106,".(102 + $i*10).",786' alt='".$files[$i]. "' href='".$files[$i]."'>\n";
    }
?>

</map>

<img usemap="#30m" src="30m-24h-view.png?cachebreak=<?=time();?>">

<br>

<a href="/ham/qrss/">Back to the DJ5CW/SO5CW QRSS main page</a>
