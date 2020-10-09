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

## photofs-fuse

A FUSE-based file system can be mounted from the image repository. This file system groups images by their tags. For example, if you tag images with `trees`, you can browse all of the images tagged with `trees` under a `trees/` directory. It also allows for some implicit tag management through file system operations (e.g., tag an image by copying that image to a tag folder).

### Installation
------------

PhotoFS is written in Ruby and requires FUSE. So far I've only tried running it on Linux.


### Usage
-----

All image and tag data is stored in a repository database that exists in a folder within your file system. Currently, the directory of the repository must be at or above all of the images you want to import into the system (think Git).

First, a repository needs to be created. This happens implicitly when a photofs is first mounted.

Images are imported into the repository using the command line.

Then tags can be applied to any images in the repository.

### File System

#### Mount

```
$ ruby mount.rb MOUNTPOINT -o source=REPOSITORY
```

Where `MOUNTPOINT` is where the virtual file system will exist within your real file system, and `REPOSITORY` is the path under which all of your image files currently exist or will exist. This will implicitly create a `.photofs` directory under the repository path.

#### Unmount

```
$ fusermount -u MOUNTPOINT
```

#### Using the File System

Deleting files under the virtual file system *does not* the original files from the file system. All images within the virtual file system are implemented as symlinks to the original files.

`MOUNTPOINT/o/`

This path will mirror everything under the `REPOSITORY` path.

`MOUNTPOINT/o/[...]/tags/`

For images that are imported into the repository under this path, there will be `tags/` subdirectories under the image paths. For example, given `o/photos/image.jpg`, and tags `cat` and `tree`, the following paths will exist:

    /o/photos/image.jpg
    /o/photos/tags/cat/
    /o/photos/tags/tree/

Copying ``image.jpg`` to ``tags/cat/`` will apply the ``cat`` tag to the image. Once the image is tagged, it will exist under the ``cat/`` path:

    /o/photos/image.jpg
    /o/photos/tags/cat/image.jpg
    /o/photos/tags/tree/

Deleting ``tags/cat/image.jpg`` removes the ``cat`` tag from ``image.jpg``.

The directories under ``tags/`` will contain all images in the parent directory that have been tagged with their respective tags. If we tagged ``image.jpg`` with ``tree``, then the file would exist under both ``cat/`` and ``tree/``.

The tag directories compound, allowing you to browse images in this path that have been tagged with multiple tags. For example, when both ``cat`` and ``tree`` have been applied to ``image.jpg``, the image file will exist under this path as well: ``o/photos/tags/cat/tree/image.jpg``, along with any other image in the parent path that had been tagged with *both* ``cat`` and ``tree``.

Deleting ``tags/cat/tree/image.jpg`` will remove *both* tags from ``image.jpg``.

`MOUNTPOINT/t/`

The top-level ``/t/`` directory behaves like the tags directories under ``/o/``, but instead of being limited to the tagged images of their respective parent directories, the tag directories under ``/t/`` contain the files that have been tagged throughout the entire repository.

Copying an image file from ``/o/`` to a tag directory under ``/t/`` will tag that image with the tag corresponding to the target directory.

For example, assume these image files

    /o/trip-to-chicago/skyscraper.jpg
    /o/hiking-trip/cliff.jpg

and tags ``architecture``, ``nature``, and ``dramatic``.

If ``skyscraper.jpg`` has been tagged with ``architecture`` and ``dramatic``, and ``cliff.jpg`` has been tagged with ``nature`` and ``dramatic``, then the ``/t/`` directory will look like this:

    /t/architecture/skyscraper.jpg
    /t/architecture/dramatic/skyscraper.jpg
    /t/dramatic/cliff.jpg
    /t/dramatic/skyscraper.jpg
    /t/dramatic/architecture/skyscraper.jpg
    /t/dramatic/nature/cliff.jpg
    /t/nature/cliff.jpg
    /t/nature/dramatic/cliff.jpg

You can remove tags from the repository by deleting their respective top-level directory under ``/t/``


Contributors
------------

Matt Schaefer (matt@situatedbit.com)

License
-------

PhotoFS is released under GNU General Public License version 3 (see LICENSE).
