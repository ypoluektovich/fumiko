Fumiko
======

Fumiko will help you keep track of web pages that are prone to change.

(It's not like I wrote her for you or anything, you d-dummy!)


Configuration
-------------

### Profiles

All configuration is kept in a so-called profile directory.
It can be anywhere on your file system, but you'll have to tell Fumiko
where exactly it is. It must be **readable and writable** to Fumiko.

### Items

In the profile directory, you define "items" for Fumiko to look after.

#### Required contents of an item directory

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

#### Simplified adding of items

Fumiko can help you add batches of items.

First, prepare a file with a list of items to add. The list must be a
text file of the following format:

    <item name 1> <url 1>
    <item name 2> <url 2>
    ...

Item names correspond to the directories that will be created in the
profile dir. You may omit `.f5` at the end of item names, Fumiko will
detect it and add the suffix automatically.

Then you run the script `f5-add.sh`. It takes one optional parameter —
the profile directory, which defaults to `.` (the current working dir).
The script reads the item definitions from standard input, so run it
like this:

    ./f5-add.sh /my/profile/dir < /my/item/list

Or like this, if you don't want to bother with creating a file for a
single item:

    ./f5-add.sh /my/profile/dir <<< "item1 http://example.com/page"

Or you may enter the items line-by-line in the console. (Tip: most
likely, your terminal uses `Ctrl+D` to send a `EOF` to the running
program's stdin.)

The created items will be using `cmp` as their diff engine.

**Warning**: currently Fumiko does not check the item names for things
like bad characters, invalid paths or items-in-items (e.g.
`outer.f5/inner.f5`), nor does she check URL well-formedness.


Running
-------

Run `f5-check.sh` with one parameter — the path to the profile
directory. (If the parameter is missing, `./profile` is assumed.)
This will trigger a check of all items.

You may specify an item directory as the parameter. In this case, only
that item will be checked.

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
