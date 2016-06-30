require "rails_helper"

RSpec.describe 'Resources' do
  context 'index' do
    context 'without a category_id' do
      let!(:resources) { create_list :resource, 4 }

      it 'returns all resources' do
        get '/resources'
        expect(response_json).to match({})
        expect(response).to be_bad_request
      end
    end

    context 'with a category_id' do
      let!(:category_a) { create :category, name: 'a' }
      let!(:category_b) { create :category, name: 'b' }
      let!(:resources) do
        create_list :resource, 2, categories: []
      end
      let!(:resources_a) do
        create_list :resource, 2, categories: [category_a]
      end
      let!(:resources_b) do
        create_list :resource, 2, categories: [category_b]
      end

      it 'returns only resources with that category' do
        get "/resources?category_id=#{category_a.id}"
        returned_ids = response_json['resources'].map { |r| r['id'] }
        expect(returned_ids).to match_array(resources_a.map(&:id))
      end
    end

    context 'with a category_id and latitude/longitude' do
      close = 10, far = 50, further = 100
      let!(:category) { create :category, name: 'a' }
      let!(:resources) do
        create_list :resource, 3, categories: [category]
      end
      let!(:address_further) { create :address, latitude: further, longitude: 0, resource: resources[0] }
      let!(:address_close) { create :address, latitude: close, longitude: 0, resource: resources[1] }
      let!(:address_far) { create :address, latitude: far, longitude: 0, resource: resources[2] }
      it 'returns the close resource before the far resource and before the further resource' do
        get "/resources?category_id=#{category.id}&lat=#{close}&long=#{close}"
        returned_address = response_json['resources'].map { |r| r['address'] }
        expect(returned_address[0]['latitude']).to match(address_close.latitude.to_s('F'))
        expect(returned_address[0]['longitude']).to match(address_close.longitude.to_s('F'))
        expect(returned_address[1]['latitude']).to match(address_far.latitude.to_s('F'))
        expect(returned_address[1]['longitude']).to match(address_far.longitude.to_s('F'))
        expect(returned_address[2]['latitude']).to match(address_further.latitude.to_s('F'))
        expect(returned_address[2]['longitude']).to match(address_further.longitude.to_s('F'))
      end
    end
  end
  context 'show' do
    let!(:resources) { create_list :resource, 4 }
    let!(:resource_a) do
      create :resource, name: 'a',
                        services: create_list(:service, 2)
    end

    it 'returns specific resource' do
      get "/resources/#{resource_a.id}"
      expect(response_json['resource']).to include(
        'id' => resource_a.id,
        'address' => Object,
        'categories' => Array,
        'schedule' => Hash,
        'phones' => Array,
        'services' => Array
      )
      service = resource_a.services.first
      expect(response_json['resource']['services'][0]).to include(
        'name' => service.name,
        'long_description' => service.long_description,
        'eligibility' => service.eligibility,
        'required_documents' => service.required_documents,
        'fee' => service.fee,
        'application_process' => service.application_process,
        'notes' => Array,
        'schedule' => Hash
      )
    end
  end
end
