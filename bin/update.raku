#!/usr/bin/env raku

use Zef::DB;
use CSV::Table;

=begin comment
use lib ".";

use DWarring;
=end comment

say "DEBUG: dwarring has ", @dwarring.elems;
my @m = <
MacOS::NativeLib
Font::FreeType
PDF
PDF::API6
PDF::Class
PDF::Content
PDF::Font::Loader
PDF::Font::Loader::HarfBuzz
PDF::Lite
>;

my $latest  = 0;
my $show    = 0;
my $remove  = 0;
my $upgrade = 0;
my $info    = 0;

if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [list=X]
   
    Given a list of Raku module names in the
    default text file list 'localmodules', uses 
    'zef' to query its databases to provide 
    information on those modules.

    Modes:
      info    - auth, ver, api
      latest  - latest version available
      remove  - remove all but the latest version
      show    - info on the installed versions
      upgrade - upgrade all if need be

    Options:
      list=X  - use list in file X
    HERE
    exit;
}

for @*ARGS {
    when /^ :i I / { 
        ++$info; 
    }
    when /^ :i r / {
         ++$remove; 
    }
    when /^ :i L / {
         ++$latest;
    }
    when /^ :i u / { 
        ++$upgrade;
    }
    default {
        say "FATAL: Unknown arg '$_'...exiting.";
        exit;
    }
}

my @auth = 'auth<zef:dwarring>', 'auth<zef:lizmat>';

my @installed;

if $latest {

    =begin comment
    #my $proc = run 'zef', 'list', '--installed', 
    my $proc = run 'zef', 'list', '--installed', 
                   :out, :err;
    my @o = $proc.out.slurp(:close).lines;
    my $e = $proc.err.slurp(:close);
    =end comment
    
    #for @m {
    when /^ :i s / { 
        ++$show; 
    }
    when /^ :i r / {
         ++$remove; 
    }
    when /^ :i L / {
         ++$latest;
    }
    when /^ :i u / { 
        ++$upgrade;
    }
    default {
        say "FATAL: Unknown arg '$_'...exiting.";
        exit;
    }
}

#my @auth = 'auth<zef:dwarring>', 'auth<zef:lizmat>';

#my @installed;

if $latest {

    =begin comment
    #my $proc = run 'zef', 'list', '--installed', 
    my $proc = run 'zef', 'list', '--installed', 
                   :out, :err;
    my @o = $proc.out.slurp(:close).lines;
    my $e = $proc.err.slurp(:close);
    =end comment
    
    #for @m {
    for @dwarring {
        my $proc = run 'zef', 'locate', $_,
                       :out, :err;
        my @o = $proc.out.slurp(:close).lines;
        my $e = $proc.err.slurp(:close);
        say "Running 'zef locate' on installed file '$_':";
        my $status = @o.head;
        say "  raw status: $status";
        my $info;
        if $status ~~ / Distribution ':' \h* (\S+) / {
            $info = ~$0;
            say "  module info: $info";
        }

#Running 'zef locate' on installed file 'MacOS::NativeLib':
#  status: ===> From Distribution: MacOS::NativeLib:ver<0.0.4>:auth<zef:lizmat>:api<>
#  info:   MacOS::NativeLib :ver<0.0.4> :auth<zef:lizmat> :api<>
        

        if $info ~~ / (.*)  
                      [ ':' ver  '<' (<[\d.]>+) '>' ] 
                      [ ':' auth '<' (<[\d.]>+) '>' ]
                      [ ':' api  '<' (<[\d.]>+) '>' ]
                    / {
               my $nam  = ~$0;
               my $ver  = ~$1;
               my $auth = ~$2;
               my $api  = ~$3;
               say "module '$nam'";
               say "  version: $ver";
               say "  author : $auth";
               say "  api    : $api";
        }

        =begin comment
        my @chunks = split(/':' [ver|auth|api]/, $info).list; 
        say "chunks:";
        say "  $_" for @chunks;
        =end comment
    }

    =begin comment
    say "Installed:";
    say "  $_" for $o.lines;
    say "  $_" for $e.lines;
    #$proc.err.slurp(:close).say;
    =end comment

    exit;

    next;

    =begin comment
    #my @cmd = <zef list --installed>.words; # | grep 'forks/PDF'";
    #say @cmd.gist;

    shell "zef list --installed";

    my $proc = run "zef", "list", '--installed', :out, :err;
    say $proc;

    my @a = $proc.out.slurp(:close).lines;
    my %a;
    for @a {
        next unless ($_.contains({@auth[0]}) or $_.contains({@auth[1]}));
        # need name, version
        say $_;
        say "test exit"; exit;
    }
    =end comment

    exit;
}


if $show {
    my $cmd = "zef list --installed"; # | grep 'forks/PDF'";

    say "  |$_|" for $cmd.words;
    exit;

    my $proc = run($cmd.words, :out, :err);
    my @a = $proc.out.slurp(:close).lines;

    #say "  |$_|" for @a;

    for @a {
        next unless ($_.contains({@auth[0]}) or $_.contains({@auth[1]}));
        say $_;
    }

    #@a = $proc.err.slurp(:close).lines;
    #say "  |$_|" for @a;

    exit;
}

if $upgrade {
    for @m { 
        my $proc = run 'zef', 'upgrade', $_, :out, :err;
        my @lines = $proc.out.slurp(:close).lines;
        my $module = @lines.head.words.tail;
     
        my $status = @lines.tail;
        if $status.contains("latest", :i) {
            $status = "Latest version";
        say "Module: $module";
        say "  Status: $status";
        next;
        }

        say "Module: $module";
        say "  Status: $status";

 
#        $proc.err.slurp(:close).say;
   #     say "debug early exit"; exit;
    }
}


