# 0.8.0 (2024-07-28)

* Hide output on assignment by @ankane in https://github.com/SciRuby/iruby/pull/312
* Introduce the new Application classes by @mrkn in https://github.com/SciRuby/iruby/pull/317
* Fix Gnuplot issues in Ruby 2.7 (#321) by @kojix2 in https://github.com/SciRuby/iruby/pull/322
* Add Ruby3.1 to CI by @kojix2 in https://github.com/SciRuby/iruby/pull/323
* Update README.md by @marek-witkowski in https://github.com/SciRuby/iruby/pull/324
* ci: upgrade actions/checkout by @kojix2 in https://github.com/SciRuby/iruby/pull/325
* Add Ruby 3.2 to CI for ubuntu by @petergoldstein in https://github.com/SciRuby/iruby/pull/327
* Default to true for `store_history` if not in silent mode by @gartens in https://github.com/SciRuby/iruby/pull/330
* Add Ruby 3.3 to CI for Ubuntu by @kojix2 in https://github.com/SciRuby/iruby/pull/331
* Remove Ruby 2.3 and 2.4 from CI by @kojix2 in https://github.com/SciRuby/iruby/pull/332
* Fix typos by @kojix2 in https://github.com/SciRuby/iruby/pull/335
* Format README.md and ci.yml by @kojix2 in https://github.com/SciRuby/iruby/pull/337
* Fix PlainBackend for irb v1.13.0 by @zalt50 in https://github.com/SciRuby/iruby/pull/339
* Added `date` to header by @ebababi in https://github.com/SciRuby/iruby/pull/342
* Update CI Configuration for IRuby by @kojix2 in https://github.com/SciRuby/iruby/pull/344
* Add logger and Remove base64 to Fix CI Tests by @kojix2 in https://github.com/SciRuby/iruby/pull/345
* Update CI trigger configuration by @kojix2 in https://github.com/SciRuby/iruby/pull/346

# 0.7.4 (2021-08-18)

## Enhancements

* Install zeromq library automatically https://github.com/SciRuby/iruby/pull/307, https://github.com/SciRuby/iruby/pull/308 (@mrkn, @kou)
* Remove pyzmq session adapter (@mrkn)
* Make cztop session adapter deprecated (@mrkn)

# 0.7.3 (2021-07-08)

## Bug Fixes

* Do not call default renderers when to_iruby_mimebundle is available (@mrkn)

# 0.7.2 (2021-06-23)

## Bug Fixes

* Fix IRuby.table for Ruby >= 2.7 https://github.com/SciRuby/iruby/pull/305 (@topofocus)
* Fix PlainBackend to include modules https://github.com/SciRuby/iruby/issues/303 (@UliKuch, @mrkn)

# 0.7.1 (2021-06-21)

## Enhancements

* Add support of `to_iruby_mimebundle` format method https://github.com/SciRuby/iruby/pull/304 (@mrkn)

## Bug Fixes

* Prevent unintentional display the result of Session#send (@mrkn)
* Update display formatter for Gruff::Base to prevent warning (@mrkn)

# 0.7.0 (2021-05-28)

## Enhancements

* The default backend is changed to IRB (@mrkn)
* Add IRuby::Kernel#switch_backend! method (@mrkn)

## Bug Fixes

* Fix the handling of image/svg+xml https://github.com/SciRuby/iruby/pull/300, https://github.com/SciRuby/iruby/pull/301 (@kojix2)

# 0.6.1 (2021-05-26)

## Bug Fixes

* Follow the messages and hooks orders during execute_request processing (@mrkn)

# 0.6.0 (2021-05-25)

## Bug Fixes

* Fix the handling of application/javascript https://github.com/SciRuby/iruby/issues/292, https://github.com/SciRuby/iruby/pull/294 (@kylekyle, @mrkn)

## Enhancements

* Add the `initialized` event in `IRuby::Kernel` class https://github.com/SciRuby/iruby/pull/168, https://github.com/SciRuby/iruby/pull/296 (@Yuki-Inoue, @mrkn)
* Add the following four events https://github.com/SciRuby/iruby/pull/295 (@mrkn):
  * `pre-execute` -- occurs before every code execution
  * `pre-run-cell` -- occurs before every non-silent code execution
  * `post-execute` -- occurs after every code execution
  * `post-run-cell` -- occurs after every non-silent code execution
* Replace Bond with IRB in PlainBackend https://github.com/SciRuby/iruby/pull/276, https://github.com/SciRuby/iruby/pull/297 (@cfis, @mrkn)

# 0.5.0 (2021-03-25)

## Bug Fixes

* Fix Jupyter console crashes issue https://github.com/SciRuby/iruby/pull/210 (@kojix2)
* Fix syntax highlighting issue on Jpyter Lab https://github.com/SciRuby/iruby/issues/224 (@kojix2)
* Fix interoperability issue with ruby-git https://github.com/SciRuby/iruby/pull/139 (@habemus-papadum)
* Fix the issue of `$stderr.write` that cannot handle multiple arguments https://github.com/SciRuby/iruby/issues/206 (@kojix2)
* Remove a buggy `inspect_request` implementation https://github.com/SciRuby/iruby/pull/119 (@LunarLanding)
* Fix uninitialized constant `Fiddle` caused in initialization phase https://github.com/SciRuby/iruby/issues/264 (@MatthewSteen, @kjoix2)
* Fix the issue on displaying a table https://github.com/SciRuby/iruby/pull/281 (@ankane)

## Enhancements

* Add `IRuby.clear_output` method https://github.com/SciRuby/iruby/pull/220 (@kojix2)
* Make backtrace on exception simplify and more appropriate for code in a cell https://github.com/SciRuby/iruby/pull/249 (@zheng-yongping)
* Make syntax error message more appropriate https://github.com/SciRuby/iruby/pull/251 (@zheng-yongping)
* Remove top-level `In` and `Out` constants https://github.com/SciRuby/iruby/pull/229 (@kojix2)
* Use text/plain for the default format of `Numo::NArray` objects https://github.com/SciRuby/iruby/pull/255 (@kojix2)
* Use ffi-rzmq as the default ZeroMQ adapter https://github.com/SciRuby/iruby/pull/256 (@kojix2)
* Drop rbczmq support https://github.com/SciRuby/iruby/pull/260 (@rstammer)
* Add ruby-vips image support https://github.com/SciRuby/iruby/pull/279 (@ankane)
* Replace mimemagic with mime-types https://github.com/SciRuby/iruby/pull/291 (@mrkn)

# 0.4.0 (2019-07-31)

(TBD)

# 0.3 (2017-03-26)

## Bug Fixes

* Disable Jupyter keyboard manager for all popups made using IRuby.popup (@kylekyle).
* Fix Iruby/Input date values bug that set date fields to whatever the last date value was (@kylekyle).
* Fix a bug where time strings put into prompter would give an 'out of range' error (@kylekyle).

## Enhancements

* Improvements to IRuby dependency detection using `Bundler::Dependencies#specs` (@kou).
* Use less memory forcing pry to store only the last 3 commands in memory (@kylekyle).
* Use bigger z-index that is used accross all browsers (@kylekyle).
* Ability to input date values as DateTime objects in IRuby/Input (@kylekyle).
* Add option to have check boxes checked by default (@kylekyle).
* Option for multi-select in drop down menus in the prompter (@kylekyle).
* Add support for multiple widgets using `IRuby::Input::Multiple` (@kylekyle).
* Calender icon for date selector icon (@kylekyle).
* Add support for Numo/NArray (@zalt50).
* Text now only completes after a space (@zalt50).
* Remove the DONTWAIT flag when receiving a message (@cloud-oak).
* Add support for CZTop (@kou).

# 0.2.9 (2016-05-02)
  
## Bug Fixes

* Fix an error where a NoMethodError was being raised where a table rendered using an Array of Hashes has more than `maxcols` columns. (@CGamesPlay)
* Patch PryBackend to throw unterminated string and unexpected end-of-file syntax errors (@kylekyle)

## Enhnacements

* Add an IRuby::Input class which provides widgets for getting inputs from users. (@kylekyle)
* Add data_uri dependency (@kylekyle)
* Added a clear_output display function (@mrkn)
* Doc fixes for installation (@kozo2, @generall)

# 0.2.8 (2015-12-06)

* Add compatibility with ffi-rzmq
* Windows support

# 0.2.7 (2015-07-02)

* Fix problem with autoloaded constants in Display, problem with sciruby gem

# 0.2.6 (2015-06-21)

* Check registered kernel and Gemfile to prevent gem loading problems
* Support to_tex method for the rendering

# 0.2.5 (2015-06-07)

* Fix #29, empty signatures
* Move iruby utils to IRuby::Utils module
* Add IRuby.tex alias for IRuby.latex
* Remove example notebooks from gem

# 0.2.4 (2015-06-02)

* Better exception handling
* Fix ctrl-C issue #17
* Fix timeout issue #19

# 0.2.3 (2015-05-31)

* Fix notebook indentation
* Fix tab completion for multiple lines

# 0.2.2 (2015-05-26)

* Support history variables In, Out, _, _i etc
* Internal refactoring and minor bugfixes

# 0.2.1 (2015-05-26)

* Copy Ruby logo to kernel specification

# 0.2.0 (2015-05-25)

* Dropped IPython2 support
* Dropped Ruby < 2.0.0 support
* Supports and requires now IPython3/Jupyter
* Switch from ffi-rzmq to rbczmq
* Added IRuby::Conn (experimental, to be used by widgets)
* iruby register/unregister commands to register IRuby kernel in Jupyter

# 0.1.13 (2014-08-19)

* Improved IRuby.table, supports :maxrows and :maxcols
* IRuby#javascript workaround (https://github.com/ipython/ipython/issues/6259)

# 0.1.12 (2014-08-01)

* IRuby#table add option maxrows
* powerful display system with format and datatype registry, see #25
* Add IRuby#javascript
* Add IRuby#svg

# 0.1.11 (2014-07-08)

* Push binding if pry binding stack is empty

# 0.1.10 (2014-07-08)

* Fix #19 (pp)
* Handle exception when symlink cannot be created
* Fix dependencies and Pry backend

# 0.1.9 (2014-02-28)

* Check IPython version

# 0.1.7/0.1.8

* Bugfixes #11, #12, #13

# 0.1.6 (2013-10-11)

* Print Matrix and GSL::Matrix as LaTeX
* Add check for Pry version

# 0.1.5 (2013-10-03)

* Implement a rich display system
* Fix error output

# 0.1.4 (2013-10-03)

* Extract display handler from kernel
* Always return a text/plain response

# 0.1.3 (2013-10-03)

* Implement missing request handlers
* Detect if Bundler is running and set kernel_cmd appropriately
* Improve Pry integration
* Add support for the gems gnuplot, gruff, rmagick and mini_magick

# 0.1.2 (2013-10-02)

* Support for Pry added
* Launch `iruby console` if plain `iruby` is started

# 0.1.0 (2013-10-02)

* Cleanup and rewrite of some parts
