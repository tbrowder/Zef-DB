#!/usr/bin/env raku

#  DEBUG module info: |- Identity: Base64::Native:ver<0.0.9>:auth<zef:dwarring>|
#   - Identity: Base64::Native:ver<0.0.9>:auth<zef:dwarring>

my $ifil = "mods.list";

my $part1 = "- Identity: "; # mod info follows
my $np1   = $part1.chars;

for $ifil.IO.lines -> $line is copy {
    my $idx = $line.index: $part1;
    say "first index = $idx; $np1 chars long";
    my $info = $line.substr: $idx+$np1;   
    say "  info data: >|$info|<";

    # we need length of the first part and the second part
    my ($len1, $len2);
    my $totlen = $info.chars;

    # we have bracketed the info line, now time to break in two
    # at the first single ':' 
    $idx = $info.rindex: '::'; # start from the last double colon (if any)
    my $idx2;
    if $idx.defined {
        # start from the double colon and find the first single colon
        # and go one position past it
        $idx2 = $info.index: ':', $idx+2;
    }
    else {
        # start from the left side and go to one postion past it
        $idx2 = $info.index: ':', $idx+2;
    }
    $idx2 += 1;
    $len1 = $idx2-1;
    $len2 = $totlen - $idx2;

    my $modname = $info.substr: 0, $len1;
    my $part2   = $info.substr: $idx2;

    say "    modname: >|$modname|<";
    say "    part2:   >|$part2|<";

    # the two parts are perfect; now break part2 into :auth: :ver, :api
    my ($auth, $ver, $api) = "auth<", "ver<", "api<";
    my ($major, $minor, $point) = 0, 0, 0;
    my $gt = ">";
    my $p0 = $part2.index: $auth;

    # $p0 must be defined
    if $p0.defined {
        $p0 += $auth.chars;
        my $pend = $part2.index: $gt, $p0;
        $pend -= 1;
        $auth = $part2.substr: $p0..$pend;
    }
    else {
        $auth = "";
    }
    say "    auth:    >|$auth|<";

    my $p1 = $part2.index: $ver;
    # $p1 must be defined
    if $p1.defined {
        $p1 += $ver.chars;
        my $pend = $part2.index: $gt, $p1;
        $pend -= 1;
        $ver = $part2.substr: $p1..$pend;
        my @c = $ver.split: '.';
        if @c.elems != 3 {
            note "WARNING: version does not have three parts, it has {@c.elems}";
            say "    ver:     >|$ver|<";
        }
        else {
            $major = @c.shift;
            $minor = @c.shift;
            $point = @c.shift;

            say "    ver:     >|$ver|<";
            say "      major:   >|$major|<";
            say "      minor:   >|$minor|<";
            say "      point:   >|$point|<";
        }

    }
    else {
        $ver = "";
    }

    my $p2 = $part2.index: $api;
    # $p2 must be defined
    if $p2.defined {
        $p2 += $api.chars;
        my $pend = $part2.index: $gt, $p2;
        $pend -= 1;
        $api = $part2.substr: $p2..$pend;
    }
    else {
        $api = "";
    }
    say "    api:     >|$api|<";

}


