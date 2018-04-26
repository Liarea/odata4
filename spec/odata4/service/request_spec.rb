require 'spec_helper'

describe OData4::Service::Request, vcr: {cassette_name: 'service/request_specs'} do
  let(:subject) { OData4::Service::Request.new(service, 'Products' ) }
  let(:service) { OData4::Service.open(service_url, name: 'ODataDemo', metadata_file: metadata_file) }
  let(:service_url) { 'http://services.odata.org/V4/OData/OData.svc' }
  let(:metadata_file) { 'spec/fixtures/files/metadata.xml' }

  describe '#url' do
    it 'returns the full request URL' do
      expect(subject.url).to eq('http://services.odata.org/V4/OData/OData.svc/Products?crossCompany=false')
    end
    it 'returns the full request URL with `crossCompany` param true if option true' do
      subject.cross_company = true
      expect(subject.url).to eq('http://services.odata.org/V4/OData/OData.svc/Products?crossCompany=true')
    end
  end

  describe '#method' do
    it 'defaults to GET' do
      expect(subject.method).to eq(:get)
    end
  end

  describe '#format' do
    it 'defaults to :auto' do
      expect(subject.format).to eq(:auto)
    end
  end

  describe '#content_type' do
    it 'return all acceptable types when format = :auto' do
      expect(subject.content_type).to eq(OData4::Service::MIME_TYPES.values.join(','))
    end

    it 'returns the correct MIME type when format = :atom' do
      subject.format = :atom
      expect(subject.content_type).to eq('application/atom+xml')
    end

    it 'returns the correct MIME type when format = :json' do
      subject.format = :json
      expect(subject.content_type).to eq('application/json')
    end
  end

  describe '#execute' do
    it 'returns a response object' do
      expect(subject.execute).to be_a(OData4::Service::Response)
    end
    it 'retries on wrong content type'
  end
end
