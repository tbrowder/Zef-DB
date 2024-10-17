[![Actions Status](https://github.com/tbrowder/Zef-DB/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/Zef-DB/actions) [![Actions Status](https://github.com/tbrowder/Zef-DB/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/Zef-DB/actions) [![Actions Status](https://github.com/tbrowder/Zef-DB/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/Zef-DB/actions)

NAME
====

**Zef::DB** - Provides Raku program 'zdb' to manage user module collections

SYNOPSIS
========

```raku
use Zef::DB;
```

DESCRIPTION
===========

**Zef::DB** can be used to test, locate, update, install, remove, and clone a user's module collection. All new data is updated into a JSON file that can be managed further by 'zdb'.

When the program is started, it expects to find one of two files that define the user's list of modules of interest.

  * localmodules.json

  * localmodules (a text file with a list of module names of interest)

The user can alternatively select another file as a start.

In either case, the result will be a JSON database. No update will be made unless the 'update' option is given.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT AND LICENSE
=====================

© 2024 Tom Browder

This library is free software; you may redistribute it or modify it under the Artistic License 2.0.

