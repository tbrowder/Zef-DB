unit module Zef::DB;

my @modules;
my $ifil;
BEGIN {
    use Text::Utils :strip-comment, :normalize-string;

    $ifil = "{$*CWD}/localmodules";
    my %modules;
    if $ifil.IO.r {
        for $ifil.IO.lines -> $line is copy {
            $line = strip-comment $line;
            next unless $line ~~ /\S+/;
            $line = normalize-string $line;
            if %modules{$line}:exists {
                say "WARNING: Module '$line' is listed more than once";
            }
            else {
                %modules{$line} = 1;
            }
        }
        @modules .= sort;
    }
}

sub help is export {
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

sub run(@args) is export  {

    my $Rinfo    = 0;
    my $Rlatest  = 0;
    my $Rremove  = 0;
    my $Rshow    = 0;
    my $Rupgrade = 0;

    my $debug   = 0;

    for @*ARGS {
        when /^ :i I / {
            ++$Rinfo;
        }
        when /^ :i L / {
            ++$Rlatest;
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
        info @modules, :$debug;
    }
    elsif $Rlatest {
        latest @modules, :$debug;
    }
    elsif $Rremove {
        remove @modules, :$debug;
    }
    elsif $Rshow {
        show @modules, :$debug;
    }
    elsif $Rupgrade {
        upgrade @modules, :$debug;
    }

}

sub info (
    @modules,
    :$debug,
    ) is export {
}

sub latest(
    @modules,
    :$debug,
    ) is export {
}

sub remove(
    @modules,
    :$debug,
    ) is export {
}

sub show(
    @modules,
    :$debug,
    ) is export {
}

sub upgrade(
    :$debug,
    ) is export {
}
