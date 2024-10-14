unit module Zef::DB;

use CSV::Table;

my @mymodules;
my $nmm;
my $ifil;
BEGIN {
    use Text::Utils :strip-comment, :normalize-string;

    $ifil = "{$*CWD}/localmodules";
    my %mymodules;
    if $ifil.IO.r {
        for $ifil.IO.lines -> $line is copy {
            $line = strip-comment $line;
            next unless $line ~~ /\S+/;
            $line = normalize-string $line;
            if %mymodules{$line}:exists {
                say "WARNING: Module '$line' is listed more than once";
            }
            else {
                @mymodules.push: $line;
                %mymodules{$line} = 1;
            }
        }
        @mymodules .= sort;
        $nmm        = @mymodules.elems;
    }
}

=begin comment
    Puts the data into a local CVS file managed by
    module 'CSV::Table' for future reference
=end comment

sub help() is export {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} <mode> [list=X]

    Given a list of Raku module names in the
    default text file list 'localmodules', uses
    'zef' to query its databases to provide
    information on those modules.

    Modes:
      i[nfo]    - Show 'zef info' distro data: auth, ver, api
      la[test]  - Uses data from 'zef info' to determine
                  latest version available
      li[st]    - List installed modules using
                  'zef list --installed'
      r[emove]  - remove all but the latest version
                  using data from 'zef info'
      s[how]    - lists names of modules of interest
      u[pgrade] - upgrade all if need be

    Options:
      list=X  - use list in file X

    HERE
    exit;
}

sub run-prog(@args) is export  {

    my $Rinfo    = 0;
    my $Rlatest  = 0;
    my $Rlist    = 0;
    my $Rremove  = 0;
    my $Rshow    = 0;
    my $Rupgrade = 0;

    my $debug    = 0;

    for @*ARGS {
        when /^ :i I / {
            ++$Rinfo;
        }
        when /^ :i LA / {
            ++$Rlatest;
        }
        when /^ :i LI / {
            ++$Rlist;
        }
        when /^ :i r / {
            ++$Rremove;
        }
        when /^ :i s / {
            ++$Rshow;
        }
        when /^ :i u / {
            ++$Rupgrade;
        }
        when /^ :i d / {
            ++$debug;
        }
        default {
            say "FATAL: Unknown arg '$_'...exiting.";
            exit;
        }
    }

    if $Rinfo {
        info @mymodules, :$debug;
    }
    elsif $Rlatest {
        latest @mymodules, :$debug;
    }
    elsif $Rremove {
        remove @mymodules, :$debug;
    }
    elsif $Rshow {
        show @mymodules, :$debug;
    }
    elsif $Rupgrade {
        upgrade @mymodules, :$debug;
    }
    exit;
}

sub info (
    @modules,
    :$debug,
) is export {
    for @modules {
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

} # sub info

sub latest(
    @modules,
    :$debug,
) is export {
    # zef info
} # sub latest

sub list(
    :$debug,
) is export {
    # zef list --installed
} # sub list

sub remove(
    @modules,
    :$debug,
    ) is export {
} # sub remove

sub show(
    @modules,
    :$debug,
    ) is export {
    
    # show local modules list
    =begin comment
    my $cmd = "zef list --installed"; # | grep 'forks/PDF'";

    if $debug {
        say "  |$_|" for $cmd.words;
       exit;
    }

    my $proc = run($cmd.words, :out, :err);
    my @a = $proc.out.slurp(:close).lines;

    if $debug {
        say "  |$_|" for @a;
    }
    =end comment

    say "Modules in your list:";
    say "  $_" for @mymodules;
    say "A total of $nmm modules in your list.";

    exit;
} # sub show

sub upgrade(
    @modules,
    :$debug,
    ) is export {
    for @modules {
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

} # sub upgrade
