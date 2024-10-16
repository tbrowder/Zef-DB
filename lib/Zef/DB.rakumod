unit module Zef::DB;

use CSV::Table;
use JSON::Fast;

my %mymodules;
my $nmm;
my $ifil;
my $jfil;
BEGIN {
    use Text::Utils :strip-comment, :normalize-string;

    # the starter file:
    $ifil = "{$*CWD}/localmodules";
    $jfil = "{$*CWD}/localmodules.json";
    my %mymodules;
    if $jfil.IO.r {
        # fill the JSON hash, no update needed
        %mymodules = from-json(slurp $jfil);
    }
    elsif $ifil.IO.r {
        # initiate the JSON hash
        for $ifil.IO.lines -> $modnam is copy {
            $modnam = strip-comment $modnam;
            next unless $modnam line ~~ /\S+/;
            $modnam = normalize-string $modnam;
            if %mymodules{$modnam}:exists {
                say "WARNING: Module '$modnam' is listed more than once";
            }
            else {
                %mymodules{$modnam}<auth> = 0;
                %mymodules{$modnam}<ver>  = 0;
                %mymodules{$modnam}<api>  = 0;
            }
        }
        $nmm = %mymodules.elems;
        # update the hash for a new JSON file
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
      upg[rade] - upgrade all if need be

      upg[date] - update the database with 'zef'
                  (note this is the only option which
                  directly uses a 'zef' ecosystem-wide
                  query and it uses a hyperized query)

    Options:
      list=X    - use list in file X

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
    my $Rupdate  = 0;

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
        when /^ :i upd / {
            ++$Rupdate;
        }
        when /^ :i upg / {
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
        # race hyper it
        # save data in a CSV file (or a hash or a JSON file!
        # do it in a TWEAK?
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
        say "Running 'zef info' on module '$_':";
        my $proc = run 'zef', 'info', $_,
                       :out, :err;
        my @o = $proc.out.slurp(:close).lines;
        my $e = $proc.err.slurp(:close);
        if $debug {
            say "  All data on '$_'";
        }
        # extract the distribution line
        my $distro;
        for @o -> $line is copy {
            if $line.contains("Identity") {
                $distro = $line;
                last;
            }
        }
        if $debug {
            say "  module info: |$distro|";
        }
        my $info = "UNKNOWN";
        if $distro ~~ / Identity ':' \h* (\S+) / {
            $info = ~$0;
            say "  module info: |$info|";
        }

        =begin comment
        # output from: zef info Foo::Bar
        ===> Searching for: Foo::Bar
        - Info for: Foo::Bar
        - Identity: Foo::Bar:ver<0.0.1>:auth<zef:tbrowder>
        - Recommended By: Zef::Repository::Ecosystems<fez>
        - Installed: Yes
        Description:	 A module for foreign module testing for Mi6::Helper \
                         development
        License:	 Artistic-2.0
        Source-url:	 https://github.com/tbrowder/Foo-Bar.git
        Provides: 1 modules
        Depends: 1 items
        =end comment

        #'zef info' on installed file 'MacOS::NativeLib':
        # ===> From Distribution: MacOS::NativeLib:ver<0.0.4>:auth<zef:lizmat>:api<>
        #  info:   MacOS::NativeLib :ver<0.0.4> :auth<zef:lizmat> :api<>
        my @modparts = $info.split('::');
        # the last part should contain the auth,ver,api
        my $endpart = @modparts.pop;
        my $modnam = @modparts.join("::");
        my @vparts = $endpart.split(':');
        # the first part contains the last of the name and the first of the auth
        my $lnam = @vparts.pop;
        $modnam ~= "::$lnam";
        my $ver = @vparts.join(":");
        if $debug {
            say "DEBUG splitting |\$info| on '::'";
            say "  mod name so far:  |$modnam|";
            say "  auth part so far: |$ver|";
        }

        #my @chunks = split(/':' [ver|auth|api]/, $info).list;
        =begin comment
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
        else {
            say "WARNING: Unrecognized format:";
            say "==> $info";
        }
        =end comment

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
