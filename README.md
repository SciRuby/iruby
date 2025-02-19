# IRuby

[![Gem Version](https://badge.fury.io/rb/iruby.svg)](https://badge.fury.io/rb/iruby)
[![Build Status](https://github.com/SciRuby/iruby/workflows/CI/badge.svg)](https://github.com/SciRuby/iruby/actions)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/RubyData/binder/master?filepath=ruby-data.ipynb)

IRuby is a Ruby kernel for [Jupyter project](http://try.jupyter.org/).

## Try IRuby

You can try IRuby with a sample notebook on Binder (the same link as the banner placed above):

<https://mybinder.org/v2/gh/RubyData/binder/master?filepath=ruby-data.ipynb>

The following URL launches JupyterLab directly on Binder.

<https://mybinder.org/v2/gh/RubyData/binder/master?filepath=../lab>

## Installation

### Requirements

* [Jupyter](https://jupyter.org)

The following requirements are automatically installed.

* [ffi-rzmq](https://github.com/chuckremes/ffi-rzmq)
* [libzmq](https://github.com/zeromq/libzmq)

The following dependencies are optional.

* [Pry][Pry], if you want to use [Pry][Pry] instead of IRB for the code execution backend

### Installing Jupyter Notebook and/or JupyterLab

See the official document to know how to install Jupyter Notebook and/or JupyterLab.

* <https://jupyter.readthedocs.io/en/latest/install/notebook-classic.html>
* <https://jupyter.readthedocs.io/en/latest/install.html>

### Ubuntu

#### Ubuntu 17+

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make

gem install --user-install iruby
iruby register --force
```

#### Ubuntu 16

The latest IRuby requires Ruby >= 2.4 while Ubuntu's official Ruby package is version 2.3.
So you need to install Ruby >= 2.4 by yourself before preparing IRuby.
We recommend to use rbenv.

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
gem install --user-install iruby
iruby register --force
```

### Fedora

#### Fedora 36

```shell
sudo dnf install ruby ruby-dev make zeromq-devel

gem install --user-install iruby
iruby register --force
```

### Windows

[DevKit](https://rubyinstaller.org/add-ons/devkit.html) is necessary for building RubyGems with native C-based extensions.

```shell
gem install iruby
iruby register --force
```

### macOS

Install ruby with rbenv or rvm.
Install Jupyter.

#### Homebrew

```shell
gem install iruby
iruby register --force
```

#### MacPorts

If you are using macports, run the following commands.

```shell
port install libtool autoconf automake autogen
gem install iruby
iruby register --force
```

### Docker

Try [RubyData Docker Stacks](https://github.com/RubyData/docker-stacks).
Running jupyter notebook:

```shell
docker run --rm -it -p 8888:8888 rubydata/datascience-notebook
```

### Installation for JRuby

You can use Java classes in your IRuby notebook.

* JRuby version >= 9.0.4.0
* iruby gem

After installation, make sure that your `env` is set up to use jruby.

```shell
env ruby -v
```

If you use RVM, it is enough to switch the current version to jruby.

If you have already used IRuby with a different version, you need to generate a new kernel:

```shell
iruby register --force
```

### Install the development version of IRuby

**Be careful to use the development version because it is usually unstable.**

If you want to install the development version of IRuby from the source code, try [specific_install](https://github.com/rdp/specific_install).

```
gem specific_install https://github.com/SciRuby/iruby
```

### Note for using with CZTop and CZMQ

[CZTop](https://gitlab.com/paddor/cztop) adapter has been deprecated since IRuby version 0.7.4.
It will be removed after several versions.

If you want to use IRuby with CZTop, you need to install it and [CZMQ](https://github.com/zeromq/czmq).

If both ffi-rzmq and cztop are installed, ffi-rzmq is used. If you prefer cztop, set the following environment variable.

```sh
export IRUBY_SESSION_ADAPTER="cztop"
```

## Backends

There are two backends: PlainBackend and PryBackend.

* PlainBackend is the default backend.  It uses [IRB](https://github.com/ruby/irb).
* PryBackend uses [Pry][Pry].

You can switch the backend to PryBackend by running the code below.

```ruby
IRuby::Kernel.instance.switch_backend!(:pry)
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

[Pry]: https://github.com/pry/pry
