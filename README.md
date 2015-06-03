***The current master branch and gem version >= 0.2 are compatible with IPython3/Jupyter. If you require IPython2 support, please install an older gem version < 0.2 or use the branch ipython2***

# IRuby

This is a Ruby kernel for IPython/Jupyter and is part of [SciRuby](http://sciruby.com/). You can try it at [try.jupyter.org](http://try.jupyter.org/).

![Screenshot](https://cloud.githubusercontent.com/assets/50754/7956845/3fa46df8-09e3-11e5-8641-f5b8669061b5.png)

### Quick start

At first install IPython/Jupyter. I recommend an installation using virtualenv.

    apt-get install python3-dev virtualenv libzmq3-dev
    virtualenv -p python3 venv
    source venv/bin/activate
    pip install 'ipython[notebook]'

After that, install the Ruby gem.

    gem install iruby

Now you can run iruby with:

    iruby
    iruby notebook

Take a look at the [Example](http://nbviewer.ipython.org/urls/raw.github.com/SciRuby/sciruby-notebooks/master/getting_started.ipynb).

### Required dependencies

* IPython/Jupyter >= 3.0.0
* libzmq >= 3.2
* Ruby >= 2.1.0

### Authors

See the [CONTRIBUTORS](CONTRIBUTORS) file.

=== License

Copyright © 2013-15, IRuby contributors and the Ruby Science Foundation.

All rights reserved.

IRuby, along with [SciRuby](http://sciruby.com/), is licensed under the MIT license. See the [LICENSE.txt](LICENSE.txt) file for details.
