require 'rails_helper'

RSpec.describe PostSerializer do
  let(:post) { Fabricate(:post) }
  let(:user) { Fabricate(:user, locale: 'en') }
  let(:serializer) { PostSerializer.new(post, scope: Guardian.new(user)) }

  describe '#can_translate' do
    it { expect(serializer.can_translate).to eq(false) }

    describe "when post detected lang matches user's locale" do
      before do
        post.custom_fields[DiscourseTranslator::DETECTED_LANG_CUSTOM_FIELD] = 'en'
        post.save
      end

      it { expect(serializer.can_translate).to eq(false) }
    end

    describe "when post detected lang does not match user's locale" do
      before do
        post.custom_fields[DiscourseTranslator::DETECTED_LANG_CUSTOM_FIELD] = 'ja'
        post.save
      end

      it { expect(serializer.can_translate).to eq(true) }
    end
  end
end
