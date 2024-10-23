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
    if $jfil.IO.r {
        # fill the JSON hash, no update needed
        %mymodules = from-json(slurp $jfil);
    }
    elsif $ifil.IO.r {
        # initiate the JSON hash
        for $ifil.IO.lines -> $modnam is copy {
            $modnam = strip-comment $modnam;
            next if $modnam !~~ /\S+/;
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

      upd[ate]  - update the database with 'zef'
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
        info %mymodules, :$debug;
    }
    elsif $Rlatest {
        latest %mymodules, :$debug;
    }
    elsif $Rremove {
        remove %mymodules, :$debug;
    }
    elsif $Rshow {
        show %mymodules, :$debug;
    }
    elsif $Rupgrade {
        upgrade %mymodules, :$debug;
    }
    exit;
}

sub info (
    %modules,
    :$debug,
) is export {

    my $n    =  0;
    my $maxn =  7;
    for %modules.keys.sort {
        ++$n;
#       if $debug {
#           next unless $n == $maxn;
#       }

        say "Running 'zef info' on module '$_':";
        my $proc = run 'zef', 'info', $_,
                       :out, :err;
        my @o = $proc.out.slurp(:close).lines;
        my $e = $proc.err.slurp(:close);
        if $debug {
            say "  DEBUG data on '$_'";
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
            say "  DEBUG module info: |$distro|";
            next;
        }
        my $info = "UNKNOWN";
        if $distro ~~ / Identity ':' \h* (\S+) / {
            $info = ~$0;
            say "  module $n Identity info: |$info|" if $debug and $n > 1;
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

        =begin comment
        Running 'zef info' on module 'Base64::Native':
          All data on 'Base64::Native'
          module info: |- Identity: Base64::Native:ver<0.0.9>:auth<zef:dwarring>|
          module info: |Base64::Native:ver<0.0.9>:auth<zef:dwarring>|
        DEBUG splitting |$info| on '::'
          mod name so far:  |Base64::dwarring>|
          auth part so far: |Native:ver<0.0.9>:auth<zef|
        DEBUG: exit from sub 'info'
        =end comment

        my @parts1   = $info.split('::', :v, :skip-empty);
        my @modparts = @parts1;
        my $endpart  = @modparts.pop;
        my $modnam   = @modparts.join('');

        #my @parts2 = $endpart.split(':', :v, :skip-empty);
        #my @parts2 = $endpart.split(':', :skip-empty);
        my @parts2 = $endpart.split(':', 2);
        $modnam ~= @parts2.shift;

        my $chunk = @parts2.join('');
        say "DEBUG: \$chunk = '$chunk'";
        my $i1 = $chunk.index:  ':';
        my $i2 = $chunk.rindex: ':';

        # chumks 1..3 so far are ok
        # auth
        my $c1 = $chunk.substr: 0, $i1;
        # ver
        my $c2 = $chunk.substr: $i1+1..$i2-1;
        # api
        my $c3 = $chunk.substr: $i2+1;

        if 0 and $debug {
             say "DEBUG: c1 = '$c1'";
             say "DEBUG: c2 = '$c2'";
             say "DEBUG: c3 = '$c3'";
        }


        my ($auth, $ver, $api) = "", "", "";;
        # version parts:
        my ($major, $minor, $point) = "", "", "";;
        for ($c1, $c2, $c3).kv -> $i, $s {
            say "DEBUG: \@chunks i = $i, s = '$s'";
            if $s ~~ /auth/ {
                $auth = $s;
            }
            elsif $s ~~ /ver/ {
                $ver  = $s;
            }
            elsif $s ~~ /api/ {
                $api  = $s;
            }
            else {
                die "FATAL: Unexpected chunk '$s'"
            }
        }
        for ($auth, $ver, $api).kv -> $i, $s {
            my $i1 = $s.index: '<';
            my $i2 = $s.rindex: '>';
            my $contents = $s.substr: $i1+1..$i2-1;
            say "DEBUG: contents for chunk $s = '$contents'" if $debug;
            if $i == 0 {
                 $auth = $contents;
            }
            elsif $i == 1 {
                $ver = $contents;
                my @s = $ver.split: '.';
                my $ne = @s.elems;
                unless $ne == 3 {
                    die "FATAL: version elements == $ne (should be 3)";
                }
                $major = @s.shift if @s.elems;
                $minor = @s.shift if @s.elems;
                $point = @s.shift if @s.elems;
            }
            elsif $i == 2 {
               $api = $contents;
            }
      
        }

        =begin comment
        if $auth ~~ / 'auth\<' \h* (\S+) '>' \h* / {
            my $s = ~$0;
            $auth = $s;
        }
        else {
            say "DEBUG: auth = '$auth'";
        }
        if $ver  ~~ / 'ver\<' \h* (\S+) '>' \h* / {
            my $s = ~$0;
            $ver = $s;
            my @s = $s.split: '.';
            my $ne = @s.elems;
            unless $ne == 3 {
                die "FATAL: version elements == $ne (should be 3)";
            }
            $major = @s.shift;
            $minor = @s.shift;
            $point = @s.shift;
        }
        else {
            say "DEBUG: ver = '$ver'";
        }
        if $api  ~~ / 'api\<' \h* (\S+) '>' \h* / {
            my $s = +$0;
            $api = $s;
        }
        else {
            say "DEBUG: api = '$api'";
        }
        =end comment

        if $debug {
            say "DEBUG:";
            say "\$modnam  = '$modnam'";
            say "  auth = '$auth'";
            say "  ver:";
            say "    major = '$major'";
            say "    minor = '$minor'";
            say "    point = '$point'";
            say "  api = '$api'";
        }

        =begin comment
        # the first part should contain the module name
        my $modname = @modparts.head;

        # the last part should contain the auth,ver,api
        my $endpart = @modparts.tail;
        #@modparts.push: $endpart;
        #my $modnam = @modparts.join("::");

        if $debug {
            say "DEBUG splitting |\$info| on '::'";
            say "  mod name so far: |$modname|";
            say "  end part so far: |$endpart|";
        }

        =begin comment
        my @vparts = $endpart.split(':');
        # the first part contains the last of the name and the first of the auth
        my $lnam = @vparts.pop;
        $modnam ~= "::$lnam";
        my $ver = @vparts.join(":");

        #my @chunks = split(/':' [ver|auth|api]/, $info).list;
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

        if $debug {
            if $n == $maxn {
                say "DEBUG: exit from sub 'info'";
                exit;
            }
        }
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
    say "  $_" for %mymodules.keys.sort;
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
