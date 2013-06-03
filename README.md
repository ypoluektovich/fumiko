Fumiko
======

Fumiko will help you keep track of web pages that are prone to change.


Configuration
-------------

### Profiles

All configuration is kept in a so-called profile directory.
It can be anywhere on your file system, but you'll have to tell Fumiko
where exactly it is. It must be **readable and writable** to Fumiko.

### Items

In the profile directory, you define "items" for Fumiko to look after.

An item is a directory, located (almost) anywhere in the profile
directory's subtree, the name of which has the suffix `.f5`. (There is
a small catch: an item directory can't contain other item directories
in its subtree.) The directories' names should not contain any funny
characters, as Fumiko is not yet experienced enough to handle them.
Most importantly, whitespace is prohibited.

In the item directory, you must create two files: `url` and `diff`.

The file `url` must contain the URL of the page you want Fumiko to
track.

The file `diff` must be an executable with the following properties:

  * it must take two parameters — names of text files to compare;
  * it must return an exit code as follows:
    
    - `0` (zero) if the files are equal;
    - `1` (one) if the files are different;
    - anything else if there is trouble.
    
    Basically, similar to the exit codes of the `cmp` utility.
    (In fact, for pages that do not require any special comparison
    logic, symlinking to `cmp` is an acceptable idea.)


Running
-------

Run `f5-check.sh` with one parameter — the path to the profile
directory. (If the parameter is missing, `./profile` is assumed.)
This will trigger a check of all items.

Fumiko needs a temporary directory to work. She uses the `mktemp -d`
command to create it, and deletes it after she is finished.

Where is the result?
--------------------

After (successfully) running the check, in the item directory you will
find a directory `revisions`. It will contain:

  * compressed snapshots of the item. The snapshots will be named after
    the timestamps of their retrieval;
  * a symlink called `latest` to — you guessed it — the latest snapshot.

The snapshots are tarballs compressed with xz. Their contents are:

  * `content` — the file with the item's content, as retrieved from the
    Net;
  * `header` — the HTTP headers of the item server's response;
  * `timestamp` — the time at which the snapshot was retrieved.

In the near future Fumiko will learn how to list and extract the
snapshots.
