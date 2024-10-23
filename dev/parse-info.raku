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
    say "  info data: >|$info|<"

}


