#! /usr/bin/perl

    use strict;
    use warnings;

#    my $Time = 'time ';                            # Time commands ?
    my $Time = '';                                  # Time commands ?
    my $Quiet = '-quiet';                           # Muzzle blithering from Netpbm components ?

    my $Compressed = '.gz';                         # Extension if components files compressed

    my ($iwidth, $iheight) = (9896, 1575);          # Width, height of rectangular images
    my $minImageSize = 480;                         # Smallest image it's worth generating

    my $png = 0;                                    # Create images as lossless PNG ?

    my $query = $ENV{'QUERY_STRING'};

    #   Crack the query into the %args hash

    my %args;
    while ($query =~ s/(\w+)=([^&]*)&?//) {
        $args{$1} = $2;
    }

    my $fallout = 0;                                # Computing fallout dose rate ?
    my ($ftime, $doserate, $yield, $range, $sburst);

    #   Note that we must constrain all parameters obtained from the request
    #   to be within our bounds, as we cannot rely upon the JavaScript code
    #   on the client side to catch all errors (it may be disabled, or the
    #   user may be rolling their own request URLs).

    if (defined($args{ftime})) {
        numarg('ftime', 1);
        numarg('ftunit', 1);
        numarg('doserate', 10000);

        #   Obtain time after detonation and dose rate for fallout calculation

        $fallout = 1;
        $ftime = $args{ftime} * $args{ftunit};
        $doserate = $args{doserate};

        $ftime = constrain($ftime, 0.2, 30 * 24);
        $doserate = constrain($doserate, 1, 10000);
    } else {
        numarg('yield', 20);
        numarg('yunit', 1);
        numarg('range', 3);
        decarg('runit', 1);

        #   Obtain yield in kilotons and range in miles for weapons effect calculation

        $yield = $args{yield} * $args{yunit};
        $range = $args{range} * $args{runit};
        $sburst = defined($args{sburst}) && ($args{sburst} eq 'y');

        $yield = constrain($yield, 1, 20000);
        $range = constrain($range, 0.05, 100);
    }

    my $rotate = 0;
    my $imsize = 800;

    if (defined($args{rotate})) {
        numarg('rotate', 0);
        $rotate = $args{rotate};
        $rotate = constrain($rotate, 0, 360);
    }
    if (defined($args{imsize})) {
        numarg('imsize', 800);
        $imsize = $args{imsize};            # Image size
        #   Constrain image size between minimum and our max resolution
        $imsize = constrain($imsize, $minImageSize, $iheight);
    }

    my $ict = 'jpeg';
    my $ifilt = 'pnmtojpeg -progressive';
    if ($png) {
        $ict = 'png';
        $ifilt = 'pnmtopng -interlace -compress 9';
    }

    if ((defined $args{image}) && ($args{image} eq 'y')) {

        print("Content-type: image/$ict\r\n");
        my $ruri = $ENV{'REQUEST_URI'};
        printf("Content-Location: $ruri\r\n");
        print("\r\n");

        #       Generate the custom image for the specified arguments

        $rotate += 270;
        my $grot = int(($iwidth * $rotate) / 360.0);

        my $ypixel = ($sburst ? 134 : 0) + $grot + (4740 - log($yield) / 0.002585);
        while ($ypixel < 0) {
            $ypixel += $iwidth;
        }
        $ypixel %= $iwidth;

        my $dpixel = $grot + (6854 - log($range / 0.05) / 0.000865);
        while ($dpixel < 0) {
            $dpixel += $iwidth;
        }
        $dpixel %= $iwidth;

        my $ipixel = $grot + int($iwidth / 4);
        while ($ipixel < 0) {
            $ipixel += $iwidth;
        }
        $ipixel %= $iwidth;

        system("$Time ppmsliderule $Quiet " .
               "-shift " . $ypixel . " " .
               "basefront.ppm$Compressed" .
               " " .
               "-shift " . $dpixel . " " .
               "outwheel.ppm$Compressed" . " " .
               "-shift " . $ipixel . " " .
               "inwheel.ppm$Compressed" . " " .
               "| ppmcirctorect -background rgb:C0/C0/C0 -circle |" .
               " pnmscale -height $imsize |" .
               " $ifilt");

    } elsif ((defined $args{bimage}) && $args{bimage} eq 'y') {

        #   Generate image of back of computer

        print("Content-type: image/$ict\r\n");
        my $ruri = $ENV{'REQUEST_URI'};
        printf("Content-Location: $ruri\r\n");
        print("\r\n");

        #       Generate the custom image for the specified arguments

        $rotate += 270;
        my $grot = int(($iwidth * $rotate) / 360.0);

        my $ypixel = $grot + (1976 + log($yield) / 0.002585);
        while ($ypixel < 0) {
            $ypixel += $iwidth;
        }
        $ypixel %= $iwidth;

        my $dpixel = ($sburst ? 134 : 0) + $grot + ((1080 + 6854) + log($range / 0.05) / 0.000865);
        while ($dpixel < 0) {
            $dpixel += $iwidth;
        }
        $dpixel %= $iwidth;

        my $ipixel = ($sburst ? 134 : 0) + $grot + (4953 + int($iwidth / 4));
        while ($ipixel < 0) {
            $ipixel += $iwidth;
        }
        $ipixel %= $iwidth;

        system("ppmsliderule $Quiet " .
               "-shift " . $ypixel . " " .
               "baseback.ppm$Compressed" .
               " " .
               "-shift " . $dpixel . " " .
               "curveback.ppm$Compressed" . " " .
               "-shift " . $ipixel . " " .
               "cursback.ppm$Compressed" . " " .
               "| ppmcirctorect -background rgb:C0/C0/C0 -circle |" .
               " pnmscale -height $imsize |" .
               " $ifilt");

    } elsif ((defined $args{fimage}) && ($args{fimage} eq 'y')) {

        #       Generate image for fallout decay

        print("Content-type: image/$ict\r\n");
        my $ruri = $ENV{'REQUEST_URI'};
        printf("Content-Location: $ruri\r\n");
        print("\r\n");

        $rotate += 270;
        my $grot = int(($iwidth * $rotate) / 360.0);

        my $ypixel = $grot;
        while ($ypixel < 0) {
            $ypixel += $iwidth;
        }
        $ypixel %= $iwidth;

        my $dpixel = $grot + (4938 - (log($ftime / 720) / -0.00164513));
        while ($dpixel < 0) {
            $dpixel += $iwidth;
        }
        $dpixel %= $iwidth;

        my $ipixel = $grot + (144 + (log($doserate / 10000) / -0.00198234));
        while ($ipixel < 0) {
            $ipixel += $iwidth;
        }
        $ipixel %= $iwidth;

        system("$Time ppmsliderule $Quiet " .
               "-shift " . $ypixel . " " .
               "basefront.ppm$Compressed" .
               " " .
               "-shift " . $dpixel . " " .
               "outwheel.ppm$Compressed" . " " .
               "-shift " . $ipixel . " " .
               "inwheel.ppm$Compressed" . " " .
               "| ppmcirctorect -background rgb:C0/C0/C0 -circle |" .
               " pnmscale -height $imsize |" .
               " $ifilt");

  } else {

        #   Generate HTML for results page

        print("Content-type: text/html\r\n");
        print("\r\n");
        my $requri = $ENV{REQUEST_URI};

        $requri =~ s/&/&amp;/g;

        print << "EOD";
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Nuclear Bomb Effects Computer</title>
<style type="text/css">
    DIV.bodycopy {
        margin-left: 15%;
        margin-right: 10%
    }
</style>
<meta name="keywords" content="nuclear, bomb, effects, computer, calculator, weapon, slide, rule" />
<meta name="description" content="Nuclear Bomb Effects Computer" />
<meta name="author" content="John Walker" />
<meta name="robots" content="index" />
<script type="text/javascript" language="JavaScript" src="/bombcalc/bombcalc.js">
</script>
</head>

<body bgcolor="#FFFFFF">
<div class="bodycopy">

<center>
<h1>
Nuclear Bomb Effects Computer
</h1>
<big><b><em>Online Edition</em></b></big><br />
by <a href="/">John Walker</a>
</center>
<br clear="left" />

<hr />

<center>

<p />

EOD

        genmap("rmap", $imsize, 36, $rotate, $requri);          # Generate image map for rotation

        #   Generate the stateless image request embedded in the result document.
        #   Note that if this is a request for a fallout rate calculation, we show
        #   only the front of the computer.

        if ($fallout) {
            print << "EOD";
<img src="$requri&amp;fimage=y" width="$imsize" height="$imsize"  usemap="#rmap" border="0" alt="Bomb effects computer image: fallout" />
<center>
<small><em>Click in image to rotate sector to top.</em></small>
</center>

<p />
EOD
            falloutForm();
            effectForm();
        } else {

            print << "EOD";
<img src="$requri&amp;image=y" width="$imsize" height="$imsize"  usemap="#rmap" border="0"  alt="Bomb effects computer image: front" />

<p />
<center>
<small><em>Click in images to rotate sector to top.</em></small>
</center>
<p />

<img src="$requri&amp;bimage=y" width="$imsize" height="$imsize"  usemap="#rmap" border="0"  alt="Bomb effects computer image: back" />
<p />

EOD
            effectForm();
            falloutForm();
        }

    print << "EOD";

</center>

<h3><a href="/bombcalc/instructions.html" target="Fourmilab_Bombcalc_Instructions">Reading Bomb Computer Results</a></h3>

<h3><cite><a href="/etexts/www/effects/" target="Fourmilab_Bombcalc_Effects">The Effects
of Nuclear Weapons</a></cite></h3>

<h3>Back to <cite><a href="/bombcalc/">Nuclear Bomb Effects Computer</a></cite></h3>

<h3><a href="/">Fourmilab Home Page</a></h3>

<p />
<hr />
<table align="right">
<tr><td align="center">
    <a href="http://validator.w3.org/check?uri=referer"
       target="_blank"><img src="/images/icons/valid-xhtml10.png"
          alt="Valid XHTML 1.0" height="31" width="88"
       border="0" /></a>
</td></tr>
</table>
<address>
by <a href="/">John Walker</a><br />
June 2005
</address>

</div>
</body>
</html>
EOD

    }


    #   Generate request form for new weapon effects calculation

    sub effectForm {

        if (!defined($args{yield})) {
            $args{yield} = 20;
            $args{yunit} = 1;
            $args{range} = 3;
            $args{runit} = 1;
        }

        my @ckyield = ($args{yunit} == 1? 'checked="checked"' : '',
                       $args{yunit} != 1 ? 'checked="checked"' : '');
        my @ckrange = ($args{runit} == 1 ? 'checked="checked"' : '',
                       $args{runit} != 1 ? 'checked="checked"' : '');
        my $cksurf = $sburst ? 'checked="checked"' : '';

        print << "EOD";
<form method="get" action="/cgi-bin/Bombcalc" onsubmit="return checkCalc(this)">
<table bgcolor="#D0D0D0" border="2" cellpadding="5" width="66%">

    <tr>
    <th colspan="3" align="center">
    Weapon Effects Calculation
    </th>
    </tr>

    <tr>
    <td>
    Yield:</td>
    <td>
    <input type="text" name="yield" value="$args{yield}" size="10" /></td>
    <td>
    <input type="radio" name="yunit" $ckyield[0] value="1" />&nbsp;Kilotons
    <input type="radio" name="yunit" $ckyield[1] value="1000" />&nbsp;Megatons
    <br />
    <input type="checkbox" name="sburst" $cksurf value="y" />&nbsp;Surface burst thermal effects?
    </td>
    </tr>

    <tr>
    <td>
    Range:</td>
    <td>
    <input type="text" name="range" value="$args{range}" size="10" /></td>
    <td>
    <input type="radio" name="runit" $ckrange[0] value="1" />&nbsp;Miles
    <input type="radio" name="runit" $ckrange[1] value="0.62137119" />&nbsp;Kilometres
    </td>
    </tr>

    <tr>
    <td colspan="3" align="center">
    <input type="submit" value=" Update " />
    </td>
    </tr>

    <tr>
    <td>
    Rotate:</td>
    <td>
    <input type="text" name="rotate" value="$args{rotate}" size="10" /></td>
    <td>
    Degrees counterclockwise
    </td>
    </tr>

    <tr>
    <td>
    Image size:</td>
    <td>
    <input type="text" name="imsize" value="$imsize" size="10" /></td>
    <td>
    Pixels
    </td>
    </tr>

</table>
<p />
</form>
EOD
    }


    #   Generate request form for new fallout calculation

    sub falloutForm {

        if (!defined($args{ftime})) {
            $args{ftime} = 1;
            $args{ftunit} = 1;
            $args{doserate} = 10000;
        }

        my @cktime = ($args{ftunit} == 1? 'checked="checked"' : '',
                      $args{ftunit} != 1 ? 'checked="checked"' : '');

        print << "EOD";
<form method="get" action="/cgi-bin/Bombcalc" onsubmit="return checkFallout(this)">
<table bgcolor="#D0D0D0" border="2" cellpadding="5" width="66%">

    <tr>
    <th colspan="3" align="center">
    Fallout Rate Calculation
    </th>
    </tr>

    <tr>
    <td>
    Time after detonation:</td>
    <td>
    <input type="text" name="ftime" value="$args{ftime}" size="10" /></td>
    <td>
    <input type="radio" name="ftunit" $cktime[0] value="1" />&nbsp;Hours
    <input type="radio" name="ftunit" $cktime[1] value="24" />&nbsp;Days
    </td>
    </tr>

    <tr>
    <td>
    Relative dose rate:</td>
    <td>
    <input type="text" name="doserate" value="$args{doserate}" size="10" /></td>
    <td>
    Arbitrary units
    </td>
    </tr>

    <tr>
    <td colspan="3" align="center">
    <input type="submit" value=" Calculate " />
    </td>
    </tr>

    <tr>
    <td>
    Rotate:</td>
    <td>
    <input type="text" name="rotate" value="$args{rotate}" size="10" /></td>
    <td>
    Degrees counterclockwise
    </td>
    </tr>

    <tr>
    <td>
    Image size:</td>
    <td>
    <input type="text" name="imsize" value="$imsize" size="10" /></td>
    <td>
    Pixels
    </td>
    </tr>

</table>
<p />
</form>
EOD
    }

    #   Generate a radial image map to rotate the computer image when the
    #   user clicks within it.

    sub genmap {
        my ($mapname, $isize, $nsegs, $rotate, $href) = @_;

        print("<map name=\"$mapname\" id=\"$mapname\">\n");

        my $Pi = atan2(1, 1) * 4;

        my $hangle = ($Pi * 2) / ($nsegs *  2);
        my $hisize = int($isize / 2);
        my ($ctrx, $ctry) = ($hisize, $hisize);

        for (my $n = 0; $n < $nsegs; $n++) {
            my ($a1, $a2) = (((($Pi * 2) / $nsegs) * $n) - $hangle,
                             ((($Pi * 2) / $nsegs) * $n) + $hangle,
                            );
            my $rangle = $rotate + (180 - rint((360 / $nsegs) * $n));
            while ($rangle < 0) {
                $rangle += 360;
            }
            while ($rangle >= 360) {
                $rangle -= 360;
            }

            my ($sin1, $cos1, $sin2, $cos2) =
                (
                    sin($a1), cos($a1), sin($a2), cos($a2)
                );

            my $scale;
            if (abs($sin1) < abs($cos1)) {
                $scale = $hisize / abs($cos1);
            } else {
                $scale = $hisize / abs($sin1);
            }
            ($sin1, $cos1) = ($ctrx + rint($sin1 * $scale), $ctry + rint($cos1 * $scale));

            $sin1-- if ($sin1 >= ($isize - 1));
            $cos1-- if ($cos1 >= ($isize - 1));

            if (abs($sin2) < abs($cos2)) {
                $scale = $hisize / abs($cos2);
            } else {
                $scale = $hisize / abs($sin2);
            }
            ($sin2, $cos2) = ($ctrx + rint($sin2 * $scale), $ctry + rint($cos2 * $scale));

            $sin2-- if ($sin2 >= ($isize - 1));
            $cos2-- if ($cos2 >= ($isize - 1));

            $href =~ m/(^.*rotate=)[^&]*(.*$)/;
            my $hr = "$1$rangle$2";

            print("    <area shape=\"poly\" coords=\"$ctrx,$ctry,$sin1,$cos1,$sin2,$cos2\" alt=\"Rotate $rangle degrees\"\n");
            print("          href=\"$hr\" />\n");
#print("gdImageLine(im, $ctrx, $ctry, $sin1, $cos1, white); /* $n $rangle  $hr*/\n");
#print("gdImageLine(im, $sin1, $cos1, $sin2, $cos2, white); /* $n */\n");
#print("gdImageLine(im, $sin2, $cos2, $ctrx, $ctry, white); /* $n */\n");
        }

        print("</map>\n");
    }

    #   Round a floating point value to the nearest integer.  This
    #   is hideously inefficient but we only do it when generating the
    #   image map.

    sub rint {
        my ($r) = @_;

        return sprintf("%.0f", $r);
    }

    #   Validate a supposedly integer argument and set it to a
    #   specified default is it is found not to be numeric.

    sub numarg {
        my ($argname, $default) = @_;

        if (!($args{$argname} =~ m/^\d+$/)) {
#print(STDERR "Fixed $argname of '$args{$argname}', set to $default.\n");
            $args{$argname} = $default;
        }
    }

    #   Validate a supposedly decimal argument and set it to a
    #   specified default is it is found not to be numeric.

    sub decarg {
        my ($argname, $default) = @_;

        if (!($args{$argname} =~ m/^\d+(\.\d+)?$/)) {
#print(STDERR "Fixed $argname of '$args{$argname}', set to $default.\n");
            $args{$argname} = $default;
        }
    }

    #   Constrain a numeric value to fall within a specified
    #   range.  If outside, the value is set to the closest limit
    #   of the range.

    sub constrain {
        my ($v, $min, $max) = @_;

        $v = $min if ($v < $min);
        $v = $max if ($v > $max);
        return $v;
    }
