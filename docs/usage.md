# ruby_pkg
*Ruby package manager.*  
**You are at [usage.md](usage.md)**  
[*Go to index*](index.md)
- - - - - - - - - - - - - - - - - -

## Command usage
```bash
ruby_pkg <install|remove|--help>
```

### --help
Usage:
```bash
ruby_pkg --help
```
* Prints some information about commands, options, and packages.
* Provides a link to [this page](easyhelp.md)

### install
Usage:
```bash
ruby_pkg install [-u (provides -s)] [-surl_service] [-g] <package>
```

#### Options
* *-u* This package is going to be from a **URL**, not **local**.
* *-s* The service to be used for url instalation. *-u* is required for this option to have effect.
* *-g* Use **tgz**, not **txz**

#### Rules
1. If *-u* is not specified, install locally.
2. If *-u* is specified, install from url only.
3. Dont mix up **tgz** and **txz**. They are different.

#### Example
```bash
./ruby_pkg install hello-world.tar.xz
```

### remove
Usage:
```bash
ruby_pkg remove <package>
```

#### Rules
1. If the package is not installed, throw an error.

#### Example
```bash
./ruby_pkg remove hello-world
```
