# IRuby

This is a Ruby kernel for IPython.

![IRuby Notebook](screenshot.png)

### Quick start

At first install the packages `ipython`, `python-jinja`, `python-tornado`, `python-pyzmq` so that you get a working `ipython notebook`.
Maybe the packages are called slightly different on your Unix.

Now install the rubygem using `gem install iruby` and then run `iruby notebook` or `iruby`.

Take a look at the [Example Notebook](http://nbviewer.ipython.org/urls/raw.github.com/minad/iruby/master/IRuby-Example.ipynb).

The IRuby notebook requires `ipython` >= 1.2.0. Furthermore we need `libzmq` >= 3.2 to work. Version 2.2.0 will not work. If you're using an old Debian without a new enough version of `libzmq`, you can install [Anaconda](https://store.continuum.io/), a Python distribution with newer versions.

### Authors

See the [CONTRIBUTORS](CONTRIBUTORS) file.

### License

See the [LICENSE](LICENSE) file.
