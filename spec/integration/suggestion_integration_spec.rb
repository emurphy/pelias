require 'spec_helper'

describe 'exclude local_admin' do

  INDEX = "spec-suggest-#{Time.now.to_i}"
  CLEANUP = false

  let(:suggest) { Pelias::Search.suggest(term, 50, INDEX) }
  let(:options) { suggest['suggestions'][0]['options'] }
  let(:options?) { suggest['suggestions'][0].include? 'options'}

  before(:all) do
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!

    schema_json =  JSON.parse(File.read('config/pelias_schema.json'))
    Pelias::ES_CLIENT.indices.create(index: INDEX, body: schema_json)
  end

  before(:each) do
    status = Pelias::ES_CLIENT.indices.status index: INDEX
    index_status = status['indices'][INDEX]
    unless index_status.include? 'docs' && index_status['docs']['num_docs'] > 0
      ids = File.open("#{File.dirname(__FILE__)}/qs_ids/#{term}.txt", 'r').readlines
      ids.each do |id|
        parts = id.split(':')
        Pelias::QuattroIndexer.perform_async parts[1], parts[2], INDEX
      end
    end
  end

  after(:all) do
    if CLEANUP
      status = Pelias::ES_CLIENT.indices.status
      indices = status['indices']
      indices.each_key do |index|
        if index =~ /spec-suggest-.*/
          Pelias::ES_CLIENT.indices.delete index: index
        end
      end
    end
  end

  context 'Chicago' do

    let(:term) { 'chicago' }

    it 'should respond' do
      expect(suggest).to_not be_nil
    end

    it 'should have suggestions' do
      expect(suggest).to include 'suggestions'
      expect(suggest['suggestions']).to have(1).items
    end

    describe 'options' do

      before :each do
        pending 'Options tests error when there are no suggestions' unless options?
      end

      it 'should have 3 options' do
          expect(options).to have(3).items
      end

      it 'should have geoname id in all options' do
        options.each { |o| expect(o['payload']['gn_id']).to_not be_nil}
      end

      it 'should have Chicago locality as top result' do
        expect(options[0]['payload']['_id'].strip).to eql 'qs:locality:6919'
      end

    end
  end

end