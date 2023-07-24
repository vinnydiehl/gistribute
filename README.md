# gistribute

gistribute is a simple file distribution system based on [GitHub
Gists](https://gist.github.com/).

I decided to make gistribute when I found myself sharing configuration files
and such with others by placing all of them into a Gist along with a little
Bash script that `curl`ed all of the files, via their raw URLs, to the right
location on the other's computer. This program removes the need to make that
script, and the need to update the raw URLs in that script whenever you edit
a file in the Gist.

## Installation

```sh
gem install gistribute
```

## How It Works

gistribute looks at the filename that you enter on Gist to find all of the
data that it needs to download the file to the other user's computer. It
allows you to choose what gistribute will call the file when it is installing
it, and where it will install the file.

If, for example, you were sharing a `~/.vimrc` file, and you wanted gistribute to
call it "Vim configuration" when it was installing it, you would name the file
`Vim configuration || ~|.vimrc`. If the filename contains the sequence `||`,
anything before that will be considered the description of that file, and
anything after it the installation path. If there is no `||`, gistribute will
use the name of the file (without the path to it) as the default description.

## Usage

For a detailed description of the available options, try one of the following:

```sh
gistribute upload -h
gistribute install -h
```

### Uploads

To upload a gistribution, use the `upload` subcommand and pass in as many files
or directories as you would like. Directories will be recursively processed and
uploaded. The install paths will be the same ones that were used on your
system. The home directory will be handled automatically.

```sh
gistribute upload ~/.bashrc ~/.bash_profile
```

### Downloads

If the resulting Gist link was, for example, `https://gist.github.com/user/123456`,
the receiver would be able to run either of these commands to download the files
to `~/.bashrc` and `~/.bash_profile`:

```sh
gistribute install 123456
gistribute install https://gist.github.com/user/123456
```
