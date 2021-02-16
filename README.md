# IRuby

[![Gem Version](https://badge.fury.io/rb/iruby.svg)](https://badge.fury.io/rb/iruby)
[![Build Status](https://github.com/SciRuby/iruby/workflows/CI/badge.svg)](https://github.com/SciRuby/iruby/actions)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/RubyData/binder/master?filepath=ruby-data.ipynb)

IRuby is a Ruby kernel for [Jupyter project](http://try.jupyter.org/).

## Installation

### Requirements

* [Jupyter](https://jupyter.org)
* One of the following is required
    * [ffi-rzmq](https://github.com/chuckremes/ffi-rzmq) and [libzmq](https://github.com/zeromq/libzmq)
    * [CZTop](https://gitlab.com/paddor/cztop) and [CZMQ](https://github.com/zeromq/czmq)

If both ffi-rzmq and cztop are installed, ffi-rzmq is used. If you prefer cztop, set the following environment variable.

```sh
export IRUBY_SESSION_ADAPTER="cztop"
```

* We recommend the [Pry](https://github.com/pry/pry) backend for full functionality.
* If you want to install the latest version of IRuby from the source code, try [specific_install](https://github.com/rdp/specific_install).

```
gem specific_install https://github.com/SciRuby/iruby
```

### Ubuntu

Install Jupyter with [Anaconda](https://www.anaconda.com/) (recommended).

#### Ubuntu 17+

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
sudo apt install libzmq3-dev libczmq-dev

gem install ffi-rzmq
gem install iruby --pre
iruby register --force
```

#### Ubuntu 16

CZTop requires CZMQ >= 4.0.0 and ZMQ >= 4.2.0. The official packages for Ubuntu 16.04 don't satisfy these version requrements, so you need to install from source.

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
sudo apt install git libzmq-dev autoconf pkg-config
git clone https://github.com/zeromq/czmq
cd czmq
./autogen.sh && ./configure && sudo make && sudo make install

gem install cztop
gem install iruby --pre
iruby register --force
```

### Windows

Install git and Jupyter with [Anaconda](https://www.anaconda.com/) (recommended).
[DevKit](https://rubyinstaller.org/add-ons/devkit.html) is necessary for building RubyGems with native C-based extensions.

Install ZeroMQ.
```shell
pacman -S mingw64/mingw-w64-x86_64-zeromq
```

```shell
gem install ffi-rzmq
gem install iruby --pre
iruby register --force
```

### macOS

Install ruby with rbenv or rvm.
Install Jupyter with [Anaconda](https://www.anaconda.com/) (recommended).

#### Homebrew

```shell
brew install automake gmp libtool wget
brew install zeromq --HEAD
brew install czmq --HEAD
```

```shell
# export LIBZMQ_PATH=$(brew --prefix zeromq)/lib
# export LIBCZMQ_PATH=$(brew --prefix czmq)/lib
# gem install cztop
gem install ffi-rzmq
gem install iruby --pre
iruby register --force
```

#### MacPorts

If you are using macports, run the following commands.

```shell
port install libtool autoconf automake autogen
gem install ffi-rzmq
gem install iruby
```

### Docker

Try [RubyData Docker Stacks](https://github.com/RubyData/docker-stacks). 
Running jupyter notebook:

```shell
docker run -p 8888:8888 rubydata/datascience-notebook
```

### Installation for JRuby

You can use Java classes in your IRuby notebook.

* JRuby version >= 9.0.4.0
* cztop gem
* iruby gem

After installation, make sure that your `env` is set up to use jruby.

```shell
$ env ruby -v
```

If you use RVM, it is enough to switch the current version to jruby.

If you have already used IRuby with a different version, you need to generate a new kernel:

```shell
$ iruby register --force
```

## Notebooks

Take a look at the [example notebook](http://nbviewer.ipython.org/urls/raw.github.com/SciRuby/sciruby-notebooks/master/getting_started.ipynb)
and the [collection of notebooks](https://github.com/SciRuby/sciruby-notebooks/) which includes a Dockerfile to create a containerized installation of iruby
and other scientific gems. You can find the prebuild image at [dockerhub](https://registry.hub.docker.com/u/minad/sciruby-notebooks/).

## Contributing

Contributions to IRuby are very welcome.

To former contributors

In February 2021, [IRuby became the canonical repository](https://github.com/SciRuby/iruby/issues/285) and is no longer a fork from [minrk/iruby](https://github.com/minrk/iruby). Please fork from this repository again before making pull requests. 

## License

Copyright (c) IRuby contributors and the Ruby Science Foundation.

Licensed under the [MIT](LICENSE) license.
