# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/spec_helper.rb'

describe Atom do  
  describe "Atom.parse" do
    it "should accept an IO" do
      lambda { Atom.parse(File.open('spec/fixtures/simple_single_entry.atom')) }.should_not raise_error
    end
    
    it "should raise ArgumentError with something other than IO" do
      lambda { Atom.parse(nil) }.should raise_error(ArgumentError)
    end
    
    it "should return an Atom::Feed" do
      feed = Atom.parse(File.open('spec/fixtures/simple_single_entry.atom'))
      feed.should be_an_instance_of(Atom::Feed)
    end    
  end
  
  describe 'SimpleSingleFeed' do    
    describe Atom::Feed do
      before(:each) do 
        @feed = Atom.parse(File.open('spec/fixtures/simple_single_entry.atom'))
      end
      
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
        @entry = Atom.parse(File.open('spec/fixtures/simple_single_entry.atom')).entries.first
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
    end
  end
  
  describe 'ComplexFeed' do
    describe Atom::Feed do
      before(:each) do
        @feed = Atom.parse(File.open('spec/fixtures/complex_single_entry.atom'))
      end
      
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
        @feed = Atom.parse(File.open('spec/fixtures/complex_single_entry.atom'))
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
          @feed = Atom.parse(File.open('spec/fixtures/complex_single_entry.atom'))
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
          @feed = Atom.parse(File.open('spec/fixtures/complex_single_entry.atom'))
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
        @feed = Atom.parse(File.open('spec/fixtures/complex_single_entry.atom'))
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
        @feed = Atom.parse(File.open('spec/fixtures/complex_single_entry.atom'))
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
end
