# is blog site

The info is on the site itself. Here's basic documentation for modifying it.
I will look at pull requests but it's a personal project, so don't be offended
if I don't like it!

## Local Server

1. Assuming the standard Ruby setup (recent Ruby, Rubygems, bundler), run
   `bundle install`
1. Assuming you have a browser installed (????) run:
   ```shell
   jekyll serve --watch --livereload
   ```
   or
   ```shell
   jekyll s -wl
   ```
   `serve` starts the server (it tells you the port),
   `watch` updates the pages affected by a file write, and
   `livereload` refreshes your browser if the page you're on updates.
