***The current master branch and gem version >= 0.2 are compatible with IPython3/Jupyter. If you require IPython2 support, please install an older gem version < 0.2 or use the branch ipython2***

# IRuby

This is a Ruby kernel for IPython/Jupyter and is part of [SciRuby](http://sciruby.com/). You can try it at [try.jupyter.org](http://try.jupyter.org/).

![Screenshot](https://cloud.githubusercontent.com/assets/50754/7956845/3fa46df8-09e3-11e5-8641-f5b8669061b5.png)

### Quick start
The installation instructions are divided according to environments mainly because of ZeroMQ.

#### Ubuntu/Debian
At first install IPython/Jupyter. I recommend an installation using virtualenv.

    apt-get install python3-dev virtualenv libzmq3-dev
    virtualenv -p python3 venv
    source venv/bin/activate
    pip install 'ipython[notebook]'

After that, install the Ruby gem.

    gem install rbczmq
    gem install iruby

Now you can run iruby with:

    iruby notebook

#### Windows
At first install IPython/Jupyter. I recommend an installation using [Enthought Canopy](https://www.enthought.com/).

Please update your PATH to include build tools or download the DevKit from http://rubyinstaller.org/downloads and follow [this instructions](http://github.com/oneclick/rubyinstaller/wiki/Development-Kit).

After that install ZeroMQ Legacy Stable Release 3.2.4 [x86 build for Windows XP SP3 and newer](http://miru.hk/archive/ZeroMQ-3.2.4~miru1.0-x86.exe).

Rename `libzmq-v100-mt-3_2_4.dll` to `libzmq.dll`.

Add the dll path to the PATH system variable.

Run two commands below:

    gem install ffi-rzmq
    gem install iruby

Now you can run iruby with:

    iruby notebook

#### Mac
I recommend an installation using [Anaconda](https://store.continuum.io/cshop/anaconda/).

After that, run three commands shown below.

    brew install libtool autoconf automake autogen
    gem install rbczmq
    gem install iruby

#### FreeBSD

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
### Installation for jRuby

Since jRuby is fully compatible with Ruby version 2.2, it is possible to use iruby with jRuby. 
It can be helpful if you want to use java classes in your iruby notebook.
This will require the following software:
* jRuby version >= 9.0.4.0
* ZeroMQ version >= 4.1.4 (You may have to build it from source.)
* ffi-rzmq gem
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

### After the installation

Take a look at the [example notebook](http://nbviewer.ipython.org/urls/raw.github.com/SciRuby/sciruby-notebooks/master/getting_started.ipynb)
and the [collection of notebooks](https://github.com/SciRuby/sciruby-notebooks/) which includes a Dockerfile to create a containerized installation of iruby
and other scientific gems. You can find the prebuild image at [dockerhub](https://registry.hub.docker.com/u/minad/sciruby-notebooks/).


### Required dependencies

* IPython/Jupyter >= 3.0.0
* Ruby >= 2.1.0

If you install IRuby with ffi-rzmq instead of rbczmq, libzmq >= 3.2 is added to the list above.

### Authors

See the [CONTRIBUTORS](CONTRIBUTORS) file.

### License

Copyright © 2013-15, IRuby contributors and the Ruby Science Foundation.

All rights reserved.

IRuby, along with [SciRuby](http://sciruby.com/), is licensed under the MIT license. See the [LICENSE](LICENSE) file for details.
