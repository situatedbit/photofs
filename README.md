# PhotoFS

This is the core gem for PhotoFS, a set of photo workflow tagging and organizing tools.

# Usage

## Setup

1. Create a MySQL/MariaDB database with a user
2. Create a `.photofs` directory at the root of your images repository
3. Using the cli, run from that directory `photofs init .`
4. Copy the sample `database.yml` file, and add your own details. Place that file in `./photofs/database.yml`

## Copying database migrations

Add to your `Rakefile`:

```
require 'photofs/tasks'
```

Run the following rake task:

```
rake photofs:copy_migrations
```

Contributors
------------

Matt Schaefer (matt@situatedbit.com)

License
-------

PhotoFS is released under GNU General Public License version 3 (see LICENSE).
