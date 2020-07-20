#!/usr/bin/perl
use strict;
use warnings;
use Template;
use YAML::Tiny;
use File::Slurp;
use Text::Markdown::Discount qw(markdown);
use File::stat;
use POSIX qw(strftime);

my $yaml = YAML::Tiny->read('smallblog.conf');
my $site = $yaml->[0];

my $tt = Template->new({
	INCLUDE_PATH => 'templates',
	INTERPOLATE => 1,	# Shell style ${...} variables
	#PRE_CHOMP => 1,
	POST_CHOMP => 1,
}) || die "$Template::ERROR\n";

# Takes a path to a post.md and returns a $vars hash
sub parse_post {
	my $path = shift;
	my $text = read_file($path);
	my $title;
	my @tags;
	my $date;
	my $edit_date;
	my $html;

	# Grab title
	$text =~ s/^# (?<title>.+)//;
	$title = $+{title};

	# Grab tags into an array
	$text =~ s/^tags: (?<tags>.+?)\n//ms;
	# Check if we have tags
	if ($+{tags}) {
		@tags = split(" ", $+{tags});
		# Update the global tags list
		$site->{tags}{$_} = 1 foreach (@tags);
	}

	# Grab date from path and reformat slashes to dashes
	my ($year,$month,$day) = ($path =~ m/(.*)\/(.*)\/(.*)\/.*.md/);
	$date = "$year-$month-$day";

	# Grab the file mtime with stat as edited time
	my $st = stat($path);
	my $fdt = strftime("%Y-%m-%d", localtime($st->mtime));
	$edit_date = $fdt if ($date ne $fdt);

	$html = markdown($text);

	# Local (post-specific) variables
	return {
		path		=> $path,
		title		=> $title,
		tags		=> \@tags,
		date		=> $date,
		edit_date	=> $edit_date,
		html		=> $html,
	};
}

# Takes a path to a page.md and returns a $vars hash
sub parse_page {
	my $path = shift;
	my $text = read_file($path);
	my $title;
	my @tags;
	my $html;

	# Grab title
	$text =~ s/^# (?<title>.+)//;
	#$title = $+{title};

	# Grab tags into an array
	$text =~ s/^tags: (?<tags>.+?)\n//ms;
	# Check if we have tags
	if ($+{tags}) {
		@tags = split(" ", $+{tags});
		# Update the global tags list
		$site->{tags}{$_} = 1 foreach (@tags);
	}

	$html = markdown($text);

	# Local (post-specific) variables
	return {
		path		=> $path,
		#title		=> $title,
		tags		=> \@tags,
		html		=> $html,
	};
}

# Grab markdown files from a YYYY/MM/DD/post.md structure
my @paths = split("\n", qx(ls -r blog/*/*/*/*.md));

# Parse the files into an array to save filesystem lookups
my @posts = map {parse_post($_)} @paths;

# Generate posts.md.html
foreach my $post (@posts) {
	my $vars = {
		site => $site,
		post => $post,
	};
	$tt->process('post_page.tmpl', $vars, "$post->{path}.html")
		|| die "Generating $post->{path} failed: ", $tt->error(), "\n";
}

# Generate index.html
{
	#my $limit = ${@posts} > $site->{max_posts} ? ${@posts} : $site->{max_posts};
	if ($site->{max_posts} > scalar @posts) {
		$site->{max_posts} = scalar @posts;
	}

	my $vars = {
		site => $site,
		posts => [@posts[0 .. $site->{max_posts}-1]],
	};
	$tt->process('index.tmpl', $vars, "blog/index.html")
		|| die "index.html failed: ", $tt->error(), "\n";
}

# Generate archive.html
{
	my $vars = {
		site => $site,
		posts => \@posts,
		title => 'Archives',
	};
	$tt->process('archive_page.tmpl', $vars, "blog/archive.html")
		|| die "archive.html failed: ", $tt->error(), "\n";
}

# Generate tags/index.html
{
	my $vars = {
		site => $site,
		title => 'Tags',
	};
	$tt->process('tag_index.tmpl', $vars, "blog/tags.html")
		|| die "tags/index.html failed: ", $tt->error(), "\n";
}

# Generate tags/$tag.html
foreach my $tag (keys %{ $site->{tags} }) {
	my @tag_posts = map {grep(/$tag/, @{$_->{tags}}) ? $_ : ()} @posts;

	my $vars = {
		site => $site,
		posts => \@tag_posts,
		title => $tag,
	};
	$tt->process('tag_page.tmpl', $vars, "blog/tags/$tag.html")
		|| die "tags/$tag.html failed: ", $tt->error(), "\n";
} if ($site->{tags})

# Generate feed.rss
{
	my $vars = {
		site => $site,
		posts => \@posts,
	};
	$tt->process('rss.tmpl', $vars, "blog/feed.rss")
		|| die "feed.rss failed: ", $tt->error(), "\n";
}



# Grab markdown file from home/home.md structure
#my @home_paths = split("\n", qx(ls -r home/*.md));
my @home_paths = ("home/home.md") ;

# Parse the files into an array to save filesystem lookups
my @home = map {parse_page($_)} @home_paths;

# Generate pages.md.html
foreach my $post (@home) {
	my $vars = {
		site => $site,
		post => $post,
	};
	$tt->process('web_page.tmpl', $vars, "$post->{path}.html")
	#$tt->process('web_page.tmpl', $vars, "index.html")
		|| die "Generating $post->{path} failed: ", $tt->error(), "\n";
	qx(cp "$post->{path}.html" index.html)
}



# Grab markdown file from resume/resume.md structure
#my @resume_paths = split("\n", qx(ls -r resume/*.md));
my @resume_paths = ("resume/resume.md") ;

# Parse the files into an array to save filesystem lookups
my @resume = map {parse_page($_)} @resume_paths;

# Generate pages.md.html
foreach my $post (@resume) {
	my $vars = {
		site => $site,
		post => $post,
	};
	$tt->process('web_page.tmpl', $vars, "resume/index.html")
		|| die "Generating $post->{path} failed: ", $tt->error(), "\n";
}
