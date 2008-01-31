# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'
require 'atom'
require 'atom/pub'
require 'atom/version'
require 'uri'
require 'net/http'

describe Atom::Pub do  
  describe Atom::Pub::Service do
    before(:all) do
      @service = Atom::Pub::Service.load_service(File.open('spec/app/service.xml'))
    end
      
    it "should have 2 workspaces" do
      @service.should have(2).workspaces
    end
  
    describe 'workspace 1' do
      before(:each) do
        @workspace = @service.workspaces.first
      end
    
      it "should have a title" do
        @workspace.title.should == "Main Site"
      end
    
      it "should have 2 collections" do
        @workspace.should have(2).collections
      end
    
      describe 'first collection' do
        before(:each) do
          @collection = @workspace.collections.first
        end
      
        it "should have the right href" do
          @collection.href.should == 'http://example.org/blog/main'
        end
      
        it "should have categories" do
          @collection.categories.should_not be_nil
        end
      
        it "should have a title" do
          @collection.title.should == 'My Blog Entries'
        end
      end
    
      describe 'second collection' do
        before(:each) do
          @collection = @workspace.collections[1]
        end
      
        it "should have a title" do
          @collection.title.should == 'Pictures'
        end
      
        it "should have the right href" do
          @collection.href.should == 'http://example.org/blog/pic'
        end
      
        it "should not have categories" do
          @collection.categories.should be_nil
        end
      
        it "should have 3 accepts" do
          @collection.should have(3).accepts
        end
      
        it "should accept 'image/png'" do
          @collection.accepts.should include('image/png')
        end
      
        it "should accept 'image/jpeg'" do
          @collection.accepts.should include('image/jpeg')
        end
      
        it "should accept 'image/gif'" do
          @collection.accepts.should include('image/gif')
        end
      end
    end
  
    describe 'workspace 2' do
      before(:each) do
        @workspace = @service.workspaces[1]
      end
    
      it "should have a title" do
        @workspace.title.should == 'Sidebar Blog'
      end
    
      it "should have 1 collection" do
        @workspace.should have(1).collections
      end
    
      describe 'collection' do
        before(:each) do
          @collection = @workspace.collections.first
        end
      
        it "should have a title" do
          @collection.title.should == 'Remaindered Links'
        end
      
        it "should have 1 accept" do
          @collection.should have(1).accepts
        end
      
        it "should accept 'application/atom+xml;type=entry'" do
          @collection.accepts.should include('application/atom+xml;type=entry')
        end
      
        it "should have categories" do
          @collection.categories.should_not be_nil
        end
      end
    end
  end
  
  describe Atom::Pub::Service do
    it "should load from a URL" do
      uri = URI.parse('http://example.com/service.xml')
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return(File.read('spec/app/service.xml'))
      Net::HTTP.should_receive(:get_response).with(uri).and_return(response)
      Atom::Pub::Service.load_service(uri).should be_an_instance_of(Atom::Pub::Service)
    end
    
    it "should raise ArgumentError with a non-http URL" do
      lambda { Atom::Pub::Service.load_service(URI.parse('file:/tmp')) }.should raise_error(ArgumentError)
    end
  end
  
  describe Atom::Pub::Collection do
    before(:each) do
      @collection = Atom::Pub::Collection.new(:href => 'http://example.org/blog')
      @request_headers = {'Accept' => 'application/atom+xml', 
                 'Content-Type' => 'application/atom+xml;type=entry',
                 'User-Agent' => "rAtom #{Atom::VERSION::STRING}"
                 }
    end
    
    it "should set the href from the hash" do
      @collection.href.should == 'http://example.org/blog'
    end
      
    it "should return the feed" do
      response = Net::HTTPSuccess.new(nil, nil, nil)
      response.stub!(:body).and_return(File.read('spec/fixtures/simple_single_entry.atom'))
      Net::HTTP.should_receive(:get_response).with(URI.parse(@collection.href)).and_return(response)
      @collection.feed.should be_an_instance_of(Atom::Feed)
    end
    
    it "should send a POST request when an entry is published" do      
      entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))      
                 
      response = mock_response(Net::HTTPCreated, entry.to_xml.to_s)
      
      http = mock('http')
      http.should_receive(:post).with('/blog', entry.to_xml.to_s, @request_headers).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      created = @collection.publish(entry)
      created.should == entry
    end
    
    it "should behave well when no content is returned" do      
      entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))      
                 
      response = mock_response(Net::HTTPCreated, " ")
      
      http = mock('http')
      http.should_receive(:post).with('/blog', entry.to_xml.to_s, @request_headers).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      created = @collection.publish(entry)
      created.should == entry
    end
    
    it "should copy Location into edit link of entry" do
      entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))      
                 
      response = mock_response(Net::HTTPCreated, entry.to_xml.to_s, 'Location' => 'http://example.org/edit/entry1.atom')
      
      http = mock('http')
      http.should_receive(:post).with('/blog', entry.to_xml.to_s, @request_headers).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      created = @collection.publish(entry)
      created.edit_link.should_not be_nil
      created.edit_link.href.should == 'http://example.org/edit/entry1.atom'
    end
    
    it "should update the entry when response is different" do
      entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))
      response = mock_response(Net::HTTPCreated, File.read('spec/fixtures/created_entry.atom'),
                               'Location' => 'http://example.org/edit/atom')
      
      http = mock('http')
      http.should_receive(:post).with('/blog', entry.to_xml.to_s, @request_headers).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      created = @collection.publish(entry)
      created.should == Atom::Entry.load_entry(File.open('spec/fixtures/created_entry.atom'))
    end
  end
  
  describe Atom::Entry do
    before(:each) do
      @request_headers = {'Accept' => 'application/atom+xml', 
                          'Content-Type' => 'application/atom+xml;type=entry',
                          'User-Agent' => "rAtom #{Atom::VERSION::STRING}"
                         }
    end
    
    it "should send a PUT to the edit link on save!" do
      entry = Atom::Entry.load_entry(File.open('spec/app/member_entry.atom'))
      response = mock_response(Net::HTTPSuccess, nil)
      
      http = mock('http')
      http.should_receive(:put).with('/member_entry.atom', entry.to_xml, @request_headers).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      entry.save!
    end
    
    it "should send a DELETE to the edit link on delete!" do
      entry = Atom::Entry.load_entry(File.open('spec/app/member_entry.atom'))
      response = mock_response(Net::HTTPSuccess, nil)
      
      http = mock('http')
      http.should_receive(:delete).with('/member_entry.atom', an_instance_of(Hash)).and_return(response)
      Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
      
      entry.destroy!
    end
    
    it "should raise exception on save! without an edit link" do
      entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))
      lambda { entry.save! }.should raise_error(Atom::Pub::NotSupported)
    end
    
    it "should raise exception on destroy! without an edit link" do
      entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))
      lambda { entry.destroy! }.should raise_error(Atom::Pub::NotSupported)
    end
  end
end
