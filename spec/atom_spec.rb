# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/spec_helper.rb'
require 'net/http'

describe Atom do  
  describe "Atom::Feed.load_feed" do
    it "should accept an IO" do
      lambda { Atom::Feed.load_feed(File.open('spec/fixtures/simple_single_entry.atom')) }.should_not raise_error
    end
    
    it "should raise ArgumentError with something other than IO or URI" do
      lambda { Atom::Feed.load_feed(nil) }.should raise_error(ArgumentError)
    end
    
    it "should accept a String" do
      Atom::Feed.load_feed(File.read('spec/fixtures/simple_single_entry.atom')).should be_an_instance_of(Atom::Feed)
    end
    
    it "should accept a URI" do
      uri = URI.parse('http://example.com/feed.atom')
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return(File.read('spec/fixtures/simple_single_entry.atom'))
      Net::HTTP.should_receive(:get_response).with(uri).and_return(response)
      Atom::Feed.load_feed(uri).should be_an_instance_of(Atom::Feed)
    end
    
    it "should raise ArgumentError with non-http uri" do
      uri = URI.parse('file:/tmp')
      lambda { Atom::Feed.load_feed(uri) }.should raise_error(ArgumentError)
    end
    
    it "should return an Atom::Feed" do
      feed = Atom::Feed.load_feed(File.open('spec/fixtures/simple_single_entry.atom'))
      feed.should be_an_instance_of(Atom::Feed)
    end
  end
  
  describe 'Atom::Entry.load_entry' do
    it "should accept an IO" do
      Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom')).should be_an_instance_of(Atom::Entry)
    end
    
    it "should accept a URI" do
      uri = URI.parse('http://example.org/')
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return(File.read('spec/fixtures/entry.atom'))
      Net::HTTP.should_receive(:get_response).with(uri).and_return(response)
      Atom::Entry.load_entry(uri).should be_an_instance_of(Atom::Entry)
    end
    
    it "should accept a String" do
      Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom')).should be_an_instance_of(Atom::Entry)
    end
    
    it "should raise ArgumentError with something other than IO, String or URI" do
      lambda { Atom::Entry.load_entry(nil) }.should raise_error(ArgumentError)
    end
  
    it "should raise ArgumentError with non-http uri" do
      lambda { Atom::Entry.load_entry(URI.parse('file:/tmp')) }.should raise_error(ArgumentError)
    end
  end
  
  describe 'SimpleSingleFeed' do
    before(:all) do 
      @feed = Atom::Feed.load_feed(File.open('spec/fixtures/simple_single_entry.atom'))
    end
       
    describe Atom::Feed do      
      it "should parse title" do
        @feed.title.should == 'Example Feed'
      end

      it "should parse updated" do
        @feed.updated.should == Time.parse('2003-12-13T18:30:02Z')
      end

      it "should parse id" do
        @feed.id.should == 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6'
      end

      it "should have an entries array" do
        @feed.entries.should be_an_instance_of(Array)
      end

      it "should have one element in the entries array" do
        @feed.entries.size.should == 1
      end

      it "should have an alternate" do
        @feed.alternate.should_not be_nil
      end

      it "should have an Atom::Link as the alternate" do
        @feed.alternate.should be_an_instance_of(Atom::Link)
      end

      it "should have the correct href in the alternate" do
        @feed.alternate.href.should == 'http://example.org/'
      end
    end

    describe Atom::Entry do
      before(:each) do
        @entry = @feed.entries.first
      end
      
      it "should parse title" do
        @entry.title.should == 'Atom-Powered Robots Run Amok'
      end
      
      it "should have an alternate" do
        @entry.alternate.should_not be_nil
      end
      
      it "should have an Atom::Link as the alternate" do
        @entry.alternate.should be_an_instance_of(Atom::Link)
      end
      
      it "should have the correct href on the alternate" do
        @entry.alternate.href.should == 'http://example.org/2003/12/13/atom03'
      end
      
      it "should parse id" do
        @entry.id.should == 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a'
      end
      
      it "should parse updated" do
        @entry.updated.should == Time.parse('2003-12-13T18:30:02Z')
      end
      
      it "should parse summary" do
        @entry.summary.should == 'Some text.'
      end
      
      it "should parse content" do
        @entry.content.should == 'This <em>is</em> html.'
      end
      
      it "should parse content type" do
        @entry.content.type.should == 'html'
      end
    end
  end
  
  describe 'ComplexFeed' do
    before(:all) do
      @feed = Atom::Feed.load_feed(File.open('spec/fixtures/complex_single_entry.atom'))
    end
    
    describe Atom::Feed do    
      it "should have a title" do
        @feed.title.should == 'dive into mark'
      end
      
      it "should have type on the title" do
        @feed.title.type.should == 'text'
      end
      
      it "should have a subtitle" do
        @feed.subtitle.should == 'A <em>lot</em> of effort went into making this effortless'
      end
      
      it "should have a type for the subtitle" do
        @feed.subtitle.type.should == 'html'
      end
      
      it "should have an updated date" do
        @feed.updated.should == Time.parse('2005-07-31T12:29:29Z')
      end
      
      it "should have an id" do
        @feed.id.should == 'tag:example.org,2003:3'
      end
      
      it "should have 2 links" do
        @feed.should have(2).links
      end
      
      it "should have an alternate link" do
        @feed.alternate.should_not be_nil
      end
      
      it "should have the right url for the alternate" do
        @feed.alternate.to_s.should == 'http://example.org/'
      end
      
      it "should have a self link" do
        @feed.self.should_not be_nil
      end
      
      it "should have the right url for self" do
        @feed.self.to_s.should == 'http://example.org/feed.atom'
      end
      
      it "should have rights" do
        @feed.rights.should == 'Copyright (c) 2003, Mark Pilgrim'
      end
      
      it "should have a generator" do
        @feed.generator.should_not be_nil
      end
      
      it "should have a generator uri" do
        @feed.generator.uri.should == 'http://www.example.com/'
      end
      
      it "should have a generator version" do
        @feed.generator.version.should == '1.0'
      end
      
      it "should have a generator name" do
        @feed.generator.name.should == 'Example Toolkit'
      end
      
      it "should have an entry" do
        @feed.should have(1).entries
      end
    end
    
    describe Atom::Entry do
      before(:each) do
        @entry = @feed.entries.first
      end
      
      it "should have a title" do
        @entry.title.should == 'Atom draft-07 snapshot'
      end
      
      it "should have an id" do
        @entry.id.should == 'tag:example.org,2003:3.2397'
      end
      
      it "should have an updated date" do
        @entry.updated.should == Time.parse('2005-07-31T12:29:29Z')
      end
      
      it "should have a published date" do
        @entry.published.should == Time.parse('2003-12-13T08:29:29-04:00')
      end
      
      it "should have an author" do
        @entry.should have(1).authors
      end
      
      it "should have two links" do
        @entry.should have(2).links
      end
      
      it "should have one alternate link" do
        @entry.should have(1).alternates
      end
      
      it "should have one enclosure link" do
        @entry.should have(1).enclosures
      end
      
      it "should have 2 contributors" do
        @entry.should have(2).contributors
      end
      
      it "should have names for the contributors" do
        @entry.contributors[0].name.should == 'Sam Ruby'
        @entry.contributors[1].name.should == 'Joe Gregorio'
      end
      
      it "should have content" do
        @entry.content.should_not be_nil
      end
    end
    
    describe Atom::Link do
      describe 'alternate link' do        
        before(:each) do
          @entry = @feed.entries.first
          @link = @entry.alternate
        end
        
        it "should have text/html type" do
          @link.type.should == 'text/html'
        end
        
        it "should have alternate rel" do
          @link.rel.should == 'alternate'
        end
        
        it "should have href 'http://example.org/2005/04/02/atom'" do
          @link.href.should == 'http://example.org/2005/04/02/atom'
        end
        
        it "should have 'http://example.org/2005/04/02/atom' string representation" do
          @link.to_s.should == 'http://example.org/2005/04/02/atom'
        end
      end
      
      describe 'enclosure link' do
        before(:each) do
          @entry = @feed.entries.first
          @link = @entry.enclosures.first
        end
        
        it "should have audio/mpeg type" do
          @link.type.should == 'audio/mpeg'
        end
        
        it "should have enclosure rel" do
          @link.rel.should == 'enclosure'
        end
        
        it "should have length 1337" do
          @link.length.should == 1337
        end
        
        it "should have href 'http://example.org/audio/ph34r_my_podcast.mp3'" do
          @link.href.should == 'http://example.org/audio/ph34r_my_podcast.mp3'
        end
        
        it "should have 'http://example.org/audio/ph34r_my_podcast.mp3' string representation" do
          @link.to_s.should == 'http://example.org/audio/ph34r_my_podcast.mp3'
        end
      end
    end
    
    describe Atom::Person do
      before(:each) do
        @entry = @feed.entries.first
        @person = @entry.authors.first
      end
      
      it "should have a name" do
        @person.name.should == 'Mark Pilgrim'
      end
      
      it "should have a uri" do
        @person.uri.should == 'http://example.org/'
      end
      
      it "should have an email address" do
        @person.email.should == 'f8dy@example.com'
      end
    end
    
    describe Atom::Content do
      before(:each) do        
        @entry = @feed.entries.first
        @content = @entry.content
      end
      
      it "should have 'xhtml' type" do
        @content.type.should == 'xhtml'
      end
      
      it "should have 'en' language" do
        @content.xml_lang.should == 'en'
      end
            
      it "should have the content as the string representation" do
        @content.should == '<p xmlns="http://www.w3.org/1999/xhtml"><i>[Update: The Atom draft is finished.]</i></p>'
      end
    end
  end
  
  describe 'ConformanceTests' do
    describe 'nondefaultnamespace.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/nondefaultnamespace.atom'))
      end
      
      it "should have a title" do
        @feed.title.should == 'Non-default namespace test'
      end
      
      it "should have 1 entry" do
        @feed.should have(1).entries
      end
      
      describe Atom::Entry do
        before(:all) do 
          @entry = @feed.entries.first
        end
        
        it "should have a title" do
          @entry.title.should == 'If you can read the content of this entry, your aggregator works fine.'
        end
        
        it "should have content" do
          @entry.content.should_not be_nil
        end
        
        it "should have 'xhtml' for the type of the content" do
          @entry.content.type.should == 'xhtml'
        end
        
        it "should strip the outer div of the content" do
          @entry.content.should_not match(/div/)
        end
        
        it "should keep inner xhtml of content" do
          @entry.content.should == '<p xmlns="http://www.w3.org/1999/xhtml">For information, see:</p> ' +
  			    '<ul xmlns="http://www.w3.org/1999/xhtml"> ' +
    				 '<li><a href="http://plasmasturm.org/log/376/">Who knows an <abbr title="Extensible Markup Language">XML</abbr> document from a hole in the ground?</a></li> ' +
    				 '<li><a href="http://plasmasturm.org/log/377/">More on Atom aggregator <abbr title="Extensible Markup Language">XML</abbr> namespace conformance tests</a></li> ' +
    				 '<li><a href="http://www.intertwingly.net/wiki/pie/XmlNamespaceConformanceTests"><abbr title="Extensible Markup Language">XML</abbr> Namespace Conformance Tests</a></li> ' +
    			  '</ul>'
  			end
      end
    end
    
    describe 'unknown-namespace.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/unknown-namespace.atom'))
        @entry = @feed.entries.first
        @content = @entry.content
      end
      
      it "should have content" do
        @content.should_not be_nil
      end
      
      it "should strip surrounding div" do
        @content.should_not match(/div/)
			end
			
			it "should keep inner lists" do
			  @content.should match(/<h:ul/)
			  @content.should match(/<ul/)
		  end
			
      it "should have xhtml type" do
        @content.type.should == 'xhtml'
      end      
    end
    
    describe 'linktests.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/linktests.xml'))
        @entries = @feed.entries
      end
      
      describe 'linktest1' do
        before(:all) do
          @entry = @entries[0]
        end
        
        it "should pick single alternate link without rel" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
      end
      
      describe 'linktest2' do
        before(:all) do
          @entry = @entries[1]
        end
        
        it "should be picky about case of alternate rel" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
        
        it "should be picky when picking the alternate by type" do
          @entry.alternate('text/plain').href.should == 'http://www.snellspace.com/public/linktests/alternate2'
        end
      end
      
      describe 'linktest3' do
        before(:all) do
          @entry = @entries[2]
        end
        
        it "should parse all links" do
          @entry.should have(5).links
        end
        
        it "should pick the alternate from a full list of core types" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
      end
      
      describe 'linktest4' do
        before(:all) do
          @entry = @entries[3]
        end
        
        it "should parse all links" do
          @entry.should have(6).links
        end
        
        it "should pick the first alternate from a full list of core types with an extra alternate" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
        
        it "should pick the alternate by type from a full list of core types with an extra alternate" do
          @entry.alternate('text/plain').href.should == 'http://www.snellspace.com/public/linktests/alternate2'
        end
      end
      
      describe 'linktest5' do
        before(:all) do
          @entry = @entries[4]
        end
        
        it "should parse all links" do
          @entry.should have(2).links
        end
        
        it "should pick the alternate without choking on a non-core type" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
        
        it "should include the non-core type in the list of links" do
          @entry.links.map(&:href).should include('http://www.snellspace.com/public/linktests/license')
        end
      end
      
      describe 'linktest6' do
        before(:all) do
          @entry = @entries[5]
        end
        
        it "should parse all links" do
          @entry.should have(2).links
        end
        
        it "should pick the alternate without choking on a non-core type identified by a uri" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
        
        it "should include the non-core type in the list of links identified by a uri" do
          @entry.links.map(&:href).should include('http://www.snellspace.com/public/linktests/example')
        end
      end
      
      describe 'linktest7' do
        before(:all) do
          @entry = @entries[6]
        end
        
        it "should parse all links" do
          @entry.should have(2).links
        end
        
        it "should pick the alternate without choking on a non-core type" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
        
        it "should include the non-core type in the list of links" do
          @entry.links.map(&:href).should include('http://www.snellspace.com/public/linktests/license')
        end
      end
      
      describe 'linktest8' do
        before(:all) do
          @entry = @entries[7]
        end
        
        it "should parse all links" do
          @entry.should have(2).links
        end
        
        it "should pick the alternate without choking on a non-core type identified by a uri" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/linktests/alternate'
        end
        
        it "should include the non-core type in the list of links identified by a uri" do
          @entry.links.map(&:href).should include('http://www.snellspace.com/public/linktests/example')
        end
      end
    end
    
    describe 'ordertest.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/ordertest.xml'))
      end
      
      it 'should have 9 entries' do
        @feed.should have(9).entries
      end
      
      describe 'ordertest1' do
        before(:each) do
          @entry = @feed.entries[0]
        end
        
        it "should have the correct title" do
          @entry.title.should == 'Simple order, nothing fancy'
        end
      end
      
      describe 'ordertest2' do
        before(:each) do
          @entry = @feed.entries[1]
        end
        
        it "should have the correct title" do
          @entry.title.should == 'Same as the first, only mixed up a bit'
        end
      end
      
      describe "ordertest3" do 
        before(:each) do
          @entry = @feed.entries[2]
        end
        
        it "should have the correct title" do
          @entry.title.should == 'Multiple alt link elements, which one does your reader show?'
        end
        
        it "should pick the first alternate" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/alternate'
        end
      end
      
      describe 'ordertest4' do
        before(:each) do
          @entry = @feed.entries[3]
        end
        
        it "should have the correct title" do
          @entry.title.should == 'Multiple link elements, does your feed reader show the "alternate" correctly?'
        end
        
        it "should pick the right link" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/alternate'
        end
      end
      
      describe 'ordertest5' do
        before(:each) do
          @entry = @feed.entries[4]
        end
        
        it "should have a source" do
          @entry.source.should_not be_nil
        end
        
        it "should have the correct title" do
          @entry.title.should == 'Entry with a source first'
        end
        
        it "should have the correct updated" do
          @entry.updated.should == Time.parse('2006-01-26T09:20:05Z')
        end
        
        it "should have the correct alt link" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/alternate'
        end
        
        describe Atom::Source do
          before(:each) do
            @source = @entry.source
          end
          
          it "should have an id" do
            @source.id.should == 'tag:example.org,2006:atom/conformance/element_order'
          end
          
          it "should have a title" do
            @source.title.should == 'Order Matters'
          end
          
          it "should have a subtitle" do
            @source.subtitle.should == 'Testing how feed readers handle the order of entry elements'
          end
          
          it "should have a updated" do
            @source.updated.should == Time.parse('2006-01-26T09:16:00Z')
          end
          
          it "should have an author" do
            @source.should have(1).authors
          end
          
          it "should have the right name for the author" do
            @source.authors.first.name.should == 'James Snell'
          end
          
          it "should have 2 links" do
            @source.should have(2).links
          end
          
          it "should have an alternate" do
            @source.alternate.href.should == 'http://www.snellspace.com/wp/?p=255'
          end
          
          it "should have a self" do
            @source.self.href.should == 'http://www.snellspace.com/public/ordertest.xml'
          end
        end
      end
      
      describe 'ordertest6' do
        before(:each) do
          @entry = @feed.entries[5]
        end
        
        it "should have a source" do
          @entry.source.should_not be_nil
        end

        it "should have the correct title" do
          @entry.title.should == 'Entry with a source last'
        end

        it "should have the correct updated" do
          @entry.updated.should == Time.parse('2006-01-26T09:20:06Z')
        end

        it "should have the correct alt link" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/alternate'
        end
      end
      
      describe 'ordetest7' do
        before(:each) do
          @entry = @feed.entries[6]
        end
        
        it "should have a source" do
          @entry.source.should_not be_nil
        end

        it "should have the correct title" do
          @entry.title.should == 'Entry with a source in the middle'
        end

        it "should have the correct updated" do
          @entry.updated.should == Time.parse('2006-01-26T09:20:07Z')
        end

        it "should have the correct alt link" do
          @entry.alternate.href.should == 'http://www.snellspace.com/public/alternate'
        end
      end
      
      describe 'ordertest8' do
        before(:each) do
          @entry = @feed.entries[7]
        end
        
        it "should have the right title" do
          @entry.title.should == 'Atom elements in an extension element'
        end
        
        it "should have right id" do
          @entry.id.should == 'tag:example.org,2006:atom/conformance/element_order/8'
        end
      end
      
      describe 'ordertest9' do
        before(:each) do
          @entry = @feed.entries[8]
        end
        
        it "should have the right title" do
          @entry.title.should == 'Atom elements in an extension element'
        end
        
        it 'should have the right id' do
          @entry.id.should == 'tag:example.org,2006:atom/conformance/element_order/9'
        end
      end
    end
  end
  
  describe 'pagination' do
    describe 'first_paged_feed.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/first_paged_feed.atom'))
      end
      
      it "should be first?" do
        @feed.should be_first
      end
      
      it "should not be last?" do
        @feed.should_not be_last
      end
      
      it "should have next" do
        @feed.next_page.href.should == 'http://example.org/index.atom?page=2'
      end
      
      it "should not have prev" do
        @feed.prev_page.should be_nil
      end
      
      it "should have last" do
        @feed.last_page.href.should == 'http://example.org/index.atom?page=10'
      end
      
      it "should have first" do
        @feed.first_page.href.should == 'http://example.org/index.atom'
      end
    end
    
    describe 'middle_paged_feed.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/middle_paged_feed.atom'))
      end
      
      it "should not be last?" do
        @feed.should_not be_last
      end
      
      it "should not be first?" do
        @feed.should_not be_first
      end
      
      it "should have next_page" do
        @feed.next_page.href.should == 'http://example.org/index.atom?page=4'
      end
      
      it "should have prev_page" do
        @feed.prev_page.href.should == 'http://example.org/index.atom?page=2'
      end
      
      it "should have last_page" do
        @feed.last_page.href.should == 'http://example.org/index.atom?page=10'
      end
      
      it "should have first_page" do
        @feed.first_page.href.should == 'http://example.org/index.atom'
      end
    end
    
    describe 'last_paged_feed.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/last_paged_feed.atom'))
      end
      
      it "should not be first?" do
        @feed.should_not be_first
      end
      
      it "should be last?" do
        @feed.should be_last
      end
      
      it "should have prev_page" do
        @feed.prev_page.href.should == 'http://example.org/index.atom?page=9'
      end
      
      it "should not have next_page" do
        @feed.next_page.should be_nil
      end
      
      it "should have first_page" do
        @feed.first_page.href.should == 'http://example.org/index.atom'
      end
      
      it "should have last_page" do
        @feed.last_page.href.should == 'http://example.org/index.atom?page=10'
      end
    end
    
    describe 'pagination using each_entries' do
      before(:each) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/first_paged_feed.atom'))
        
       
      end
      
      it "should paginate through each entry" do
        response1 = Net::HTTPSuccess.new(nil, nil, nil)
        response1.stub!(:body).and_return(File.read('spec/paging/middle_paged_feed.atom'))
        Net::HTTP.should_receive(:get_response).with(URI.parse('http://example.org/index.atom?page=2')).and_return(response1)

        response2 = Net::HTTPSuccess.new(nil, nil, nil)
        response2.stub!(:body).and_return(File.read('spec/paging/last_paged_feed.atom'))
        Net::HTTP.should_receive(:get_response).with(URI.parse('http://example.org/index.atom?page=4')).and_return(response2)
          
        entry_count = 0
        @feed.each_entry(:paginate => true) do |entry|
          entry_count += 1
        end
        
        entry_count.should == 3
      end
      
      it "should not paginate through each entry when paginate not true" do
        entry_count = 0
        @feed.each_entry do |entry|
          entry_count += 1
        end
        
        entry_count.should == 1
      end
      
      it "should only paginate up to since" do
        response1 = Net::HTTPSuccess.new(nil, nil, nil)
        response1.stub!(:body).and_return(File.read('spec/paging/middle_paged_feed.atom'))
        Net::HTTP.should_receive(:get_response).with(URI.parse('http://example.org/index.atom?page=2')).and_return(response1)
        Net::HTTP.should_receive(:get_response).with(URI.parse('http://example.org/index.atom?page=4')).never
        
        entry_count = 0
        @feed.each_entry(:paginate => true, :since => Time.parse('2003-11-19T18:30:02Z')) do |entry|
          entry_count += 1
        end

        entry_count.should == 1
      end
    end
  end
  
  describe Atom::Link do
    before(:each) do
      @href = 'http://example.org/next'
      @link = Atom::Link.new(:rel => 'next', :href => @href)
    end    
    
    it "should fetch feed for fetch_next" do
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return(File.read('spec/paging/middle_paged_feed.atom'))
      Net::HTTP.should_receive(:get_response).with(URI.parse(@href)).and_return(response)
      @link.fetch.should be_an_instance_of(Atom::Feed)
    end
    
    it "should fetch content when response is not xml" do
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return('some text.')
      Net::HTTP.should_receive(:get_response).with(URI.parse(@href)).and_return(response)
      @link.fetch.should == 'some text.'
    end
    
    it "should fetch content when response is not atom" do
      content = <<-END
      <?xml version="1.0" ?>
      <foo>
        <bar>text</bar>
      </foo>        
      END
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return(content)
      Net::HTTP.should_receive(:get_response).with(URI.parse(@href)).and_return(response)
      @link.fetch.should == content
    end
  end
  
  describe Atom::Entry do
    before(:all) do
      @entry = Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
    end
    
    it "should be == to itself" do
      @entry.should == Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
    end
    
    it "should be != if something changes" do
      @other = Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
      @other.title = 'foo'
      @entry.should_not == @other
    end
    
    it "should be != if content changes" do
      @other = Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
      @other.content.type = 'html'
      @entry.should_not == @other
    end
    
    it "should output itself" do
      other = Atom::Entry.load_entry(@entry.to_xml)
      @entry.should == other
    end
    
    it "should properly escape titles" do
      @entry.title = "Breaking&nbsp;Space"
      other = Atom::Entry.load_entry(@entry.to_xml)
      @entry.should == other
    end
  end
  
  describe 'Atom::Feed initializer' do
    it "should create an empty Feed" do
      lambda { Atom::Feed.new }.should_not raise_error
    end
    
    it "should yield to a block" do
      lambda do
        Atom::Feed.new do |f|
          f.should be_an_instance_of(Atom::Feed)
          throw :yielded
        end
      end.should throw_symbol(:yielded)
    end
  end
  
  describe 'Atom::Entry initializer' do
    it "should create an empty feed" do
      lambda { Atom::Entry.new }.should_not raise_error
    end
    
    it "should yield to a block" do
      lambda do
        Atom::Entry.new do |f|
          f.should be_an_instance_of(Atom::Entry)
          throw :yielded
        end
      end.should throw_symbol(:yielded)
    end
  end
  
  describe Atom::Content::Html do
    it "should escape ampersands in entities" do
      Atom::Content::Html.new("&nbsp;").to_xml.to_s.should == "<content type=\"html\">&amp;nbsp;</content>"
    end
  end
end
