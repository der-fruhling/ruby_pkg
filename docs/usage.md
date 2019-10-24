# ruby_pkg
*Ruby package manager.*  
**You are at [usage.md](usage.md)**  
[*Go to index*](index.md)
- - - - - - - - - - - - - - - - - -

## Command usage
```bash
ruby_pkg <install|remove|place|unplace|--help>
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
# Local
./ruby_pkg install packages/hello-world.tar.xz

# From this repo
./ruby_pkg install -u hello-world
# does the same as
./ruby_pkg install -u -sprimary hello-world
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

### place
*This command is internal or for debugging package installing.*  
Usage:
```bash
ruby_pkg place <directory>
```

#### Rules
1. *directory* is expected to exist and be a directory.
2. **sudo is required**

#### Example
```bash
sudo ./ruby_pkg place hello-world
```

### unplace
*This command is internal and only exists as an alternative to using remove*  
Usage:
```bash
ruby_pkg unplace <package>
```

#### Rules
1. `pkg_dirs['outside']/package.pkg_listing` must exist.
2. **sudo is required**

#### Example
```bash
sudo ./ruby_pkg unplace hello-world
```
