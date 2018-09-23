# IRuby

This is a Ruby kernel for Jupyter and is part of [SciRuby](http://sciruby.com/). You can try it at [try.jupyter.org](http://try.jupyter.org/).

![Screenshot](https://cloud.githubusercontent.com/assets/50754/7956845/3fa46df8-09e3-11e5-8641-f5b8669061b5.png)

## Quick start
The installation instructions are divided according to environments mainly because of ZeroMQ.

### Ubuntu
At first install Jupyter. I recommend an installation using [Anaconda](https://www.anaconda.com/download/) Python 3.6 version.

#### Preparing dependencies on 16.04
CZTop requires CZMQ >= 4.0.0 and ZMQ >= 4.2.0.  The official packages for Ubuntu 16.04 don't satisfy these version requrements, so you need to install from source.

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
sudo apt install git libzmq-dev autoconf pkg-config
git clone https://github.com/zeromq/czmq
cd czmq
./autogen.sh && ./configure && sudo make && sudo make install
```

#### Preparing dependencies on 17.04
In 17.04, you can use official packages.

```shell
sudo apt install libtool libffi-dev ruby ruby-dev make
sudo apt install libzmq3-dev libczmq-dev
```

#### Version-independent things
After preparing dependencies, install the Ruby gem.

```shell
gem install cztop iruby
iruby register --force
```

Now you can select Ruby kernel in Jupyter Notebook with:

    jupyter-notebook

### Windows
At first install **git** and Jupyter. I recommend an installation using [Anaconda](https://www.anaconda.com/download/).

Run the following commands on **Ruby command prompt**:

```shell
gem install cztop
gem install iruby
iruby register --force
```

Now you can select Ruby kernel in Jupyter Notebook with:

    jupyter-notebook

### Mac
I recommend an installation using [Anaconda](https://www.anaconda.com/download/).

After that, run the following commands.

```shell
brew install rbenv automake gmp libtool wget
rbenv install 2.4.1
rbenv global 2.4.1
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

brew install zeromq
brew install czmq --HEAD
gem install cztop iruby
iruby register --force
```

If you are using macports, run the following commands.

    port install libtool autoconf automake autogen
    gem install ffi-rzmq
    gem install iruby


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
    $ sudo pkg install libzmq3 py27-qt4-gui py27-pexpect-3.3 py27-qt4-svg py27-pygments py27-Jinja2 py27-tornado py27-jsonschema
    ```
4. make install using ports

    ```shell
    $ cd /usr/ports/net/py-pyzmq
    $ sudo make install
    $ cd /usr/ports/devel/ipython
    $ sudo make install
    ```
Then, install iruby and related ports and gems.
    ```shell
    $ sudo pkg install rubygem-mimemagic
    $ sudo gem install ffi-rzmq  # install ffi, ffi-rzmq-core and ffi-rzmq
    $ git clone https://github.com/SciRuby/iruby.git
    $ cd iruby
    $ gem build iruby.gemspec
    $ sudo gem install iruby-0.2.7.gem
    ```
## Installation for jRuby

Since jRuby is fully compatible with Ruby version 2.2, it is possible to use iruby with jRuby.
It can be helpful if you want to use java classes in your iruby notebook.
This will require the following software:
* jRuby version >= 9.0.4.0
* cztop gem
* this iruby gem

After installation, make sure that your `env` is set up to jruby.
```shell
$ env ruby -v
```
If you use RVM, it is enough to switch the current version to jruby.
If you have already used iruby with a different version, you need to generate a new kernel:
```shell
$ iruby register --force
```
After that you can use iruby with jRuby in usual way.

## After the installation

Take a look at the [example notebook](http://nbviewer.ipython.org/urls/raw.github.com/SciRuby/sciruby-notebooks/master/getting_started.ipynb)
and the [collection of notebooks](https://github.com/SciRuby/sciruby-notebooks/) which includes a Dockerfile to create a containerized installation of iruby
and other scientific gems. You can find the prebuild image at [dockerhub](https://registry.hub.docker.com/u/minad/sciruby-notebooks/).


## Required dependencies

* Jupyter >= 3.0.0
* Ruby >= 2.1.0

If you install IRuby with CZTop, CZMQ >= 4.0.0 is added to the list above.

If you install IRuby with ffi-rzmq, libzmq >= 3.2 is added to the list above.

## Authors

See the [CONTRIBUTORS](CONTRIBUTORS) file.

## License

Copyright © 2013-15, IRuby contributors and the Ruby Science Foundation.

All rights reserved.

IRuby, along with [SciRuby](http://sciruby.com/), is licensed under the MIT license. See the [LICENSE](LICENSE) file for details.
