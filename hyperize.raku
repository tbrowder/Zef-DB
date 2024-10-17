#!/usr/bin/env raku

use hyperize;
my @modules = < Foo::Bar hyperize >;

class MData {
    has $.info is required;
    has $.auth;
    has $.ver;
    has $.api;
    has $.installed;
    has $.description;
    has $.license;
    has $.source-url;
    has $.provides;   # number of modules
    has $.depends;    # number of dependencies
    has $.source-db;  # fez, etc.

    =begin comment
    # output from: zef info Foo::Bar
    ===> Searching for: Foo::Bar
    - Info for: Foo::Bar
    - Identity: Foo::Bar:ver<0.0.1>:auth<zef:tbrowder>
    - Recommended By: Zef::Repository::Ecosystems<fez>
    - Installed: Yes
    Description: A module for foreign module testing for Mi6::Helper \
                     development
    License:	 Artistic-2.0
    Source-url:	 https://github.com/tbrowder/Foo-Bar.git
    Provides: 1 modules
    Depends: 1 items
    =end comment
    submethod TWEAK {
        my $mnam1; # for sanity check
        my $mnam2; # for sanity check

        # break $info into lines
        my @lines = $info.lines;
        for @lines {
            when /\h* '- Info for:' \h+ (\S+) / {
                $mnam1 = ~$0;
            }
            when /\h* '- Recommended By:' \h+ (\S+) / {
            }
            when /\h* '- Installed:' \h+ (\S+) / {
            }

            # handle '- Identity:'  parts
            when /\h* '- Identity:' \h+ (\S+) / {
                my @parts = parse-indentity ~$0;
                $mnam2  = @parts.shift;
                $!auth = @parts.shift;
                $!ver  = @parts.shift;
                $!api  = @parts.shift;
            }

            # descriptive data:
            when /\h* 'Description:' \h* (\N+) / {
                my $s = ~$0;
                $!description = normalize-string $s;
            }
            when /\h* 'License:' \h* (\N+) / {
                my $s = ~$0;
                $!license = normalize-string $s;
            }
            when /\h* 'Source-url:' \h* (\S+) / {
                $!source-url = ~$0;
            }
            when /\h* 'Provides:' \h* (\d+) \h+ / {
                $!provides = +$0;
            }
            when /\h* 'Depends:' \h* (\d+) \h+ / {
                $!depends = +$0;
            }
            default {
                if $debug {
                    die qq:to/HERE;;
                    FATAL: Unhandled  arg in 'zef info'
                           parse.
                    HERE
                }
                # otherwise ignore it
            }

            unless ($!modname, $mnam1, $mnam2).equiv {
                die qq:to/HERE;;
                FATAL: module names: modname, mnam1, and
                       mnam2 are NOT identical
                HERE
            }

        }

        # take the raw $info and deconstruct it
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

    }
}

my @results = @modules.&racify(1, 8).map( {
    # do something with the input 
    # which is a line from @modules
    # stash the desired result in 
    # @results.
    # results are not in input order
    # use a class to stash results
    # here where created

    # this just adds the name of
    # current module:
    $_

    # do the analysis here...
    # from the original code
    # call another sub
    my $info = get-module-info($_);

});

sub get-module-info($modname, :$debug --> Str) is export {
    say "Running 'zef info' on module '$modname':";
    my $proc = run 'zef', 'info', $modname,
                   :out, :err;
    my $o = $proc.out.slurp(:close);
    my $e = $proc.err.slurp(:close);
    if $debug {
        say "  All data on '$modname'";
        say "    $_" for $o.lines; 
    }
    $o
}

for @results {
    say $_;
}
