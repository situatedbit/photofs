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

## photofs-cli

A command line tool for PhotoFS.

### Usage

The command line interface allows you import images and manage tags.

    ruby cli.rb help

Prints usage information.

    ruby cli.rb import DIR_PATH

Adds all images in and under ``DIR_PATH`` to the repository. Assumes that ``DIR_PATH`` is in the source file system, and that the repository is located at or above ``DIR_PATH`` in the directory tree.

    ruby cli.rb prune PATH

Scans ``PATH`` and removes all images from the repository that are no longer in the source file system at or below ``PATH``. Assumes that the repository is located at or above ``PATH`` in the directory tree.

    ruby cli.rb rename tag OLD_TAG NEW_TAG

Renames ``OLD_TAG`` to ``NEW_TAG``. Assumes that the working directory is at or above the location of the repository.

    ruby cli.rb retag OLD_TAG_LIST NEW_TAG_LIST PATH [PATH_2] [PATH_N]

Where ``PATH`` is an image path in the repository, removes all tags in ``OLD_TAG_LIST`` from that image, and applies all tags in ``NEW_TAG_LIST``. Multiple tags may be specified in the tag lists if quoted and separated by spaces.

    ruby cli.rb tag TAG_LIST PATH [PATH_2] [PATH_N]

Where ``PATH`` is an image path in the repository, applies each tag in ``TAG_LIST`` to the image. Multiple tags may be specified in the tag list if quoted and separated by spaces.

    ruby cli.rb usage

Prints usage information.


Contributors
------------

Matt Schaefer (matt@situatedbit.com)

License
-------

PhotoFS is released under GNU General Public License version 3 (see LICENSE).
