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

Gistribute looks at the files in each Gist and checks for one or two lines of
metadata at the top of the file. The metadata must begin with ```%%```, but
you may put anything before that and it won't be parsed.

The first line of metadata contains the location on the client's computer that
you wish to install the file to. The second contains the name of the file as it
will be printed on the user's screen as it is installed. If the second line is
excluded, Gistribute will use the name of the file in the Gist.

## Usage

An example follows:

```VimL
"%% ~/.vimrc
"%% Vim configuration
" This is an example .vimrc file being shared via Gistribute.
" Notice the two comments at the top containing the metadata.

set nocompatible
filetype indent plugin on
syntax on
```

If, for example, the resulting Gist link was https://gist.github.com/123456,
the user would be able to run either of these commands to download the file
to ```~/.vimrc```:

    $ gistribute 123456
    $ gistribute https://gist.github.com/123456

**Gistribute will strip the metadata from the files.** Don't worry about having
messy files on the user's computer because of the metadata sitting at the top,
as this is taken care of. Be aware, however, that if you leave a blank line
between the metadata and the first line of the file, the resulting downloaded
file **will** have a blank line at the top.

If there are files in the Gist without metadata, they will be ignored by
Gistribute.
