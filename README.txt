= rAtom

rAtom is a library for working with the Atom Syndication Format and
the Atom Publishing Protocol (APP).

* Built using libxml so it is _much_ faster than a REXML based library.
* Uses the libxml pull parser so it has much lighter memory usage.
* Supports {RFC 5005}[http://www.ietf.org/rfc/rfc5005.txt] for feed pagination.

rAtom was originally built to support the communication between a number of applications
built by Peerworks[http://peerworks.org], via the Atom Publishing protocol.  However, it 
supports, or aims to support, all the Atom Syndication Format and Publication Protocol
and can be used to access Atom feeds or to script publishing entries to a blog supporting APP.

== Prerequisites

* libxml-ruby, = 0.5.2.0
* rspec (Only required for tests)

libxml-ruby in turn requires the libxml2 library to be installed. libxml2 can be downloaded
from http://xmlsoft.org/downloads.html or installed using whatever tools are provided by your
platform.  At least version 2.6.31 is required.

=== Mac OSX

Mac OSX by default comes with an old version of libxml2 that will not work with rAtom. You
will need to install a more recent version.  If you are using Macports:

  port install libxml2

== Installation

You can install via gem using:

  gem install ratom
  
== Usage

To fetch a parse an Atom Feed you can simply:

  feed = Atom::Feed.load_feed(URI.parse("http://example.com/feed.atom"))
  
And then iterate over the entries in the feed using:

  feed.each_entry do |entry|
    # do cool stuff
  end
  
To construct a Feed

  feed = Atom::Feed.new do |feed|
    feed.title = "My Cool Feed"
    feed.id = "http://example.com/my_feed.atom"
    feed.updated = Time.now
  end
  
To output a Feed as XML use to_xml

  > puts feed.to_xml
  <?xml version="1.0"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
    <title>My Cool Feed</title>
    <id>http://example.com/my_feed.atom</id>
    <updated>2008-03-03T23:19:44+10:30</updated>
  </feed>

See Feed and Entry for details on the methods and attributes of those classes.

=== Publishing

To publish to a remote feed using the Atom Publishing Protocol, first you need to create a collection to publish to:

  require 'atom/pub'
  
  collection = Atom::Pub::Collection.new(:href => 'http://example.org/myblog')
  
Then create a new entry

  entry = Atom::Entry.new do |entry|
    entry.title = "I have discovered rAtom"
    entry.authors << Atom::Person.new(:name => 'A happy developer')
    entry.updated = Time.now
    entry.id = "http://example.org/myblog/newpost"
    entry.content = Atom::Content::Html.new("<p>rAtom lets me post to my blog using Ruby, how cool!</p>")
  end
  
And publish it to the Collection:

  published_entry = collection.publish(entry)

Publish returns an updated entry filled out with any attributes to server may have set, including information
required to let us update to the entry.  For example, lets change the content and republished:

  published_entry.content =  Atom::Content::Html.new("<p>rAtom lets me post to and edit my blog using Ruby, how cool!</p>")
  published_entry.updated = Time.now
  published_entry.save!
  
You can also delete an entry using the <tt>destroy!</tt> method, but we won't do that will we?.
    
=== Extension elements

As of version 0.3.0, rAtom support simple extension elements on feeds and entries.  As defined in the Atom Syndication Format,
simple extension elements consist of XML elements from a non-Atom namespace that have no attributes or child elements, i.e.
they are empty or only contain text content.  These elements are treated as a name value pair where the element namespace
and local name make up the key and the content of the element is the value, empty elements will be treated as an empty string.

To access extension elements use the [] method on the Feed or Entry. For example, if we are parsing the follow Atom document
with extensions:

  <?xml version="1.0"?>
  <feed xmlns="http://www.w3.org/2005/Atom" xmlns:ex="http://example.org">
    <title>Feed with extensions</title>
    <ex:myelement>Something important</ex:myelement>
  </feed>
  
We could then access the extension element on the feed using:

  > feed["http://example.org", "myelement"]
  => ["Something important"]
  
Note that the return value is an array. This is because XML allows multiple instances of the element. 

To set an extension element you append to the array:

  > feed['http://example.org', 'myelement'] << 'Something less important'
  => ["Something important", "Something less important"]
  
You can then call to_xml and rAtom will serialize the extension elements into xml.

  > puts feed.to_xml
  <?xml version="1.0"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
    <myelement xmlns="http://example.org">Something important</myelement>
    <myelement xmlns="http://example.org">Something less important</myelement>
  </feed>
  
Notice that the output repeats the xmlns attribute for each of the extensions, this is semantically the same the input XML, just a bit
ugly.  It seems to be a limitation of the libxml-Ruby API. But if anyone knows a work around I'd gladly accept a patch (or even advice).

== TODO

* Support partial content responses from the server.
* Support batching of protocol operations.
* Examples of editing existing entries.
* All my tests have been against internal systems, I'd really like feedback from those who have tried rAtom using existing blog software that supports APP.
* Handle all base uri tests.
* Add slug support.
* Handle HTTP basic authentication.

== Source Code

The source repository is accessible via GitHub:

  git clone git://github.com/seangeo/ratom.git

== Contact Information

The project page is at http://rubyforge.org/projects/ratom. Please file any bugs or feedback
using the trackers and forums there.

== Authors and Contributors

rAtom was developed by Peerworks[http://peerworks.org] and written by Sean Geoghegan.

