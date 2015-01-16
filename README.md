# smallblog
A small static blogging platform in the style of [jekyll](jekyllrb.com)

Smallblog takes markdown files organized as `blog/year/month/day/post.md` and generates an index page containing the latest few posts, and a simple way to navigate all posts. Smallblog must be re-ran every time you add or modify a post (in the spirit of static blogging.) An example site may be found [here](http://mnetic.ch/blog).

## Dependencies
Smallblog requires a markdown parser. I currently use and recommend [Discount](http://www.pell.portland.or.us/~orc/Code/discount/), which is written in C. If you're not familiar with markdown, there is a good tutorial on Wikipedia, available [here](http://en.wikipedia.org/wiki/Markdown).

## Installation
    cd ~/public_html
    mkdir blog tags
    cp main.css blog/
    echo "test" > blog/2013/08/16/test.md

Installation is simple. Just make a `blog` directory on your server, and copy the `main.css` template into it. File hierarchy under `blog` is in the form of `blog/year/month/date/post.md`. Posts must have a .md extension or they will be ignored. Multiple posts on the same date will be sorted by last modified timestamp (`ls -t`.)

## Usage
    cd ~/public_html/blog
    smallblog

To run smallblog, simply go to the folder that contains your blog, and run `smallblog` in that directory. It will generate the main page (`index.html`) in the current directory by parsing the date hierarchy folders for markdown (`.md`) files.

To use the tags features, include a `tags: ` line in your post followed by a list of tags to apply to your post.

## Configuration
Smallblog may be configured via the variables at the top of the file.
```shell
    out_file="index.html"   # The html file generated in your blog root
    title="blog"            # The title of your blog
    max_posts=3             # Maximum posts on the front page
```

## Theming
Smallblog uses the same template system as jekyll. The default smallblog template is the jekyll default.

Posts take the format of:
```html
    <p><div class="post">
    <h3 class="title"><a href'/blog/year/month/day/post.html'>Title</a></h3>
    <p class="meta">Date: year-month-day time</p>
    <p>Post text</p>
    </div></p>
```

The site should be wrapped in a `<div class="site">` and contains the standard `<div class="header">`, `<div class="footer">`, and `<div class="contact">` for the header, footer, and footer contact information styling respectively.

## Bugs
Smallblog was written under pdksh and tested under bash (both on linux.) It should be posix compliant, but please let me know if you find any bugs.

* `stat(1)` on Linux is different than the BSD version. An alternate line has been included, that may be uncommented on BSD systems. I am looking into more portable methods of finding the file access time.

## License
Smallblog is released under the ISC (2-BSD) license. Please see [LICENSE](https://github.com/abyxcos/smallblog/blob/master/LICENSE) for the full text.
