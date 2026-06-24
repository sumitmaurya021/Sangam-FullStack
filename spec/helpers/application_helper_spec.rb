require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  before do
    allow(helper.request).to receive(:base_url).and_return("http://test.host")
    allow(helper.request).to receive(:original_url).and_return("http://test.host/posts")
  end

  describe '#meta_tags' do
    it 'stores custom metadata values' do
      helper.meta_tags(title: "Custom Title", description: "Custom Description")
      expect(helper.instance_variable_get(:@meta_tags)).to include(
        title: "Custom Title",
        description: "Custom Description"
      )
    end
  end

  describe '#render_meta_tags' do
    it 'renders default meta tags' do
      rendered = helper.render_meta_tags
      expect(rendered).to include('content="Sangam"')
      expect(rendered).to include('content="Sangam - A modern full-stack social network linking people, groups, and events."')
      expect(rendered).to include('content="http://test.host/icon.svg"')
    end

    it 'renders overridden meta tags' do
      helper.meta_tags(title: "Nexus Post", description: "Hello world")
      rendered = helper.render_meta_tags
      expect(rendered).to include('content="Nexus Post"')
      expect(rendered).to include('content="Hello world"')
    end
  end
end
