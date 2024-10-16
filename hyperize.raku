#!/usr/bin/env raku

use hyperize;
my @modules = < Foo::Bar hyperize >;
my @results = 
    
    @modules.&racify(1, 8).map( {
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
    }
  );

for @results {
    say $_;
}
