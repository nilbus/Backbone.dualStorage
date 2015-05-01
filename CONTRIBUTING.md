Contributing
============

Pull requests for features, improvements, and fixes are welcome! I have limited
time to contribute to this project and therefore rely on contributors like you
to bring in the changes you need.

To submit a change request:

1. Fork the repository and make your change in a feature branch.
   You may also want to discuss the change first in an issue.
2. Compile the javascript files using the instructions below.
3. Ensure the tests pass, following the instructions below.
4. Update the changelog (CHANGES.md), summarizing the change.
   Include any relevant issue/pull request number, version numbers, and the author.
5. Open a [pull request](https://help.github.com/articles/creating-a-pull-request/)
   with your change.

This project is not on a set release schedule. If a feature you want is in
master but has not been released, feel free to ask for a release.

Compiling
---------

Compile the coffeescript into javascript with `make`. This requires that
node.js and coffee-script are installed.

    npm install -g coffee-script

    make

During development, use `make watch` to compile as you make changes.

Testing
-------

To run the test suite, clone the project and open **SpecRunner.html** in a browser.

Note that the tests run against **spec/backbone.dualstorage.js**, not the copy
in the project root.
The spec version needs to be unwrapped to allow mocking components for testing.
This version is compiled automatically when running `make`.

dualStorage has been tested against Backbone versions 0.9.2 - 1.1.2.
Test with other versions by altering the version included in `SpecRunner.html`.

Getting Help
------------

Open an issue and ask for help if you need it. I make a good effort to be responsive.
