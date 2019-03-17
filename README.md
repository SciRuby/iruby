# IRuby

[![Gem Version](https://badge.fury.io/rb/iruby.svg)](https://badge.fury.io/rb/iruby)
[![Build Status](https://travis-ci.org/SciRuby/iruby.svg?branch=master)](https://travis-ci.org/SciRuby/iruby)

IRuby is a Ruby kernel for [Jupyter project](http://try.jupyter.org/).

## Installation
How to set up [ZeroMQ](http://zeromq.org/) depends on your environment.
You can use one of the following libraries. 
* [CZTop](https://gitlab.com/paddor/cztop) and [CZMQ](https://github.com/zeromq/czmq) >= 4.0.0
* [ffi-rzmq](https://github.com/chuckremes/ffi-rzmq) and [libzmq
](https://github.com/zeromq/libzmq) >= 3.2

### Ubuntu
Install Jupyter with [Anaconda](https://www.anaconda.com/) (recommended). 

#### Setup ZeroMQ on Ubuntu 16.04
CZTop requires CZMQ >= 4.0.0 and ZMQ >= 4.2.0. The official packages for Ubuntu 16.04 don't satisfy these version requrements, so you need to install from source.

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
sudo apt install git libzmq-dev autoconf pkg-config
git clone https://github.com/zeromq/czmq
cd czmq
./autogen.sh && ./configure && sudo make && sudo make install
```

#### Setup ZeroMQ on Ubuntu 17.04 to 18.10
Use official packages.

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
sudo apt install libzmq3-dev libczmq-dev
```

#### Install CZTop and IRuby
```shell
gem install cztop
gem install iruby --pre
iruby register --force
```

### Windows
Install git and Jupyter with [Anaconda](https://www.anaconda.com/) (recommended). 
[DevKit](https://rubyinstaller.org/add-ons/devkit.html) is necessary for building RubyGems with native C-based extensions.

```shell
gem install cztop
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

Setup environment variables. 
```
export LIBZMQ_PATH=$(brew --prefix zeromq)/lib
export LIBCZMQ_PATH=$(brew --prefix czmq)/lib
```

```shell
gem install cztop
# gem install ffi-rzmq
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

### FreeBSD
At first install IPython/Jupyter. 
There is a pyzmq ports (ports/net/py-pyzmq) which depends on libzmq4, however, it doesn't works with ipython.
Therefore we use libzmq3 like the following:

1. make your ports tree up-to-date.
2. replace LIBDEPENDS line in ports/net/py-pyzmq/Makefile

```shell
LIB_DEPENDS=    libzmq.so:${PORTSDIR}/net/libzmq4
```
with
```shell
LIB_DEPENDS=    libzmq.so:${PORTSDIR}/net/libzmq3
```
3. install related packages

```shell
sudo pkg install libzmq3 py27-qt4-gui py27-pexpect-3.3 py27-qt4-svg py27-pygments py27-Jinja2 py27-tornado py27-jsonschema
```
4. make install using ports

```shell
cd /usr/ports/net/py-pyzmq
sudo make install
cd /usr/ports/devel/ipython
sudo make install
```
Then, install IRuby and related ports and gems.
```shell
sudo pkg install rubygem-mimemagic
sudo gem install ffi-rzmq  # install ffi, ffi-rzmq-core and ffi-rzmq
git clone https://github.com/SciRuby/iruby.git
cd iruby
gem build iruby.gemspec
sudo gem install iruby-0.2.7.gem
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
We welcome contributions from everyone.

## Authors
See the [CONTRIBUTORS](CONTRIBUTORS) file.

## License
Copyright © 2013-19, IRuby contributors and the Ruby Science Foundation.

All rights reserved.

IRuby, along with [SciRuby](http://sciruby.com/), is licensed under the MIT license. See the [LICENSE](LICENSE) file.
