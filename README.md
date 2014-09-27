wx-ruby-template
================

Project template for wxWidgets applications with an embedded ruby runtime.

Details
-------

After toying around with several options for developing GUI applications with ruby/jruby, I've recently began
writing my GUI logic in C++ with wxWidgets and simply embedding a ruby runtime & standard library. This repo
is a project template for such an application.

In The Box
----------

- Rake file for building with support for separate debug, release, and distribution configurations
- A bare-bones wxFormBuilder project w/ pre-generated app.xrc (containing a single blank wxFrame)
- A bare-bones MainFrame class
- A bare-bones App class that initializes ruby, releases the GVL & launches the main frame
  + Releasing the GVL before launching the main frame allows the possibility of launching
    ruby threads and having them execute in parallel to the main event loop.

Prerequisites
-------------

- Prebuilt wxWidgets libraries
- Prebuilt ruby runtime
- Prebuilt [rubydo](https://github.com/jbreeden/rubydo)
  * Allows the use of C++ lambdas when obtaining/releasing the ruby GVL & launching ruby-aware threads
  
You'll likely want to compile these from source with your preferred C++ compiler so the binaries will be compatible.
I've had success compiling wxWidgets & ruby on Windows by using [msys](http://www.mingw.org/wiki/MSYS) configured
to use [tdm-gcc](http://tdm-gcc.tdragon.net/).
  
Usage
-----

- Download the contents of this repo
- Update the rakefile to point to the correct library & header locations for the prerqeuisites mentioned above.
- Run `rake debug:build`, `rake release:build`, or `rake dist:build` to compile the bare template
- Run the generated program, and a blank wxFrame should appear

Platform Support
----------------

So far I've only used this project template on Windows 8. Though, all the libraries involved are cross-platform so
porting should be relatively straightforward.

LICENSE
-------

(The MIT License)

Copyright (c) 2014 Jared Breeden

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
