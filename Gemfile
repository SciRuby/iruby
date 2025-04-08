source 'https://rubygems.org'

plugin 'rubygems-requirements-system'

gemspec

group :pry do
  gem 'pry'
  gem 'pry-doc'
  gem 'awesome_print'
end

group :plot do
  gem 'gnuplot'
  gem 'rubyvis'
end

group :test do
  gem 'cztop'
end

# Tests are failing on Ruby 3.3 because warnings related to OpenStruct are being written to the standard error output.
# This is being captured by Open3.capture2e and then mistakenly parsed as JSON.
# This gem can be removed when json gem is updated
gem 'ostruct'
