# Gistribute

Gistribute is a simple file distribution system based on GitHub's Gist service.

I decided to make Gistribute when I found myself sharing configuration files
and such with others by placing all of them into a Gist along with a little
Bash script that curled all of the files, via their raw URLs, to the right
location on the other's computer. This program removed the need to make that
script, and the need to update the raw URLs in that script whenever you make
a tweak to one of the files that you're sharing.

## Installation

    $ gem install gistribute

## How It Works

Gistribute looks at the filename that you enter on Gist to find all of the
data that it needs to download the file to the other user's computer. It
allows you to choose what Gistribute will call the file when it is installing
it, and where it will install the file.

## Usage

If, for example, you were sharing a .vimrc file, and you wanted Gistribute to
call it "Vim configuration" when it was installing it, you would name the file
`Vim configuration||~|.vimrc`. If the filename contains the sequence `||`,
anything before that will be considered the description of that file, and
anything after it the installation path. If there is no `||`, Gistribute will
use the name of the file (without the path to it) as the default description.

The file path separator is the pipe character because GitHub Gist doesn't
allow slashes in filenames- this quirk is the result of Gist actually saving
those files to a Git repository on their servers, and handling slashes in
file names can't possibly be very nice.

If the resulting Gist link was, for example, https://gist.github.com/123456,
the user would be able to run either of these commands to download the file
to `~/.vimrc`:

```Shell
$ gistribute 123456
$ gistribute https://gist.github.com/123456
```
