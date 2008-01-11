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
end