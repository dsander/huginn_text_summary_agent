require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::TextSummaryAgent do
  before(:each) do
    @checker = Agents::TextSummaryAgent.new(name: "TextSummaryAgent", options: Agents::TextSummaryAgent.new.default_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  it 'renders the event description without errors' do
    expect { @checker.event_description }.not_to raise_error
  end

  context '#validate_options' do
    it 'is valid with the default options' do
      expect(@checker).to be_valid
    end

    it 'requires data to be set' do
      @checker.options['data'] = ""
      expect(@checker).not_to be_valid
    end

    it 'requires length to be set' do
      @checker.options['length'] = ""
      expect(@checker).not_to be_valid
    end
    it 'requires threshold to be set' do
      @checker.options['threshold'] = ""
      expect(@checker).not_to be_valid
    end
  end

  context '#receive' do
    let(:text) { "There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc." }
    let(:event) { Event.new(payload: {'data' => text}) }

    context 'merge' do
      it 'merges the result into the result_key per default' do
        expect { @checker.receive([event]) }.to change(Event, :count).by(1)
        data = Event.last.payload['data']
        expect(data).not_to be_nil
      end

      it 'does not merge when merge is set to fasle' do
        @checker.options['merge'] = 'false'
        expect { @checker.receive([event]) }.to change(Event, :count).by(1)
        data = Event.last.payload['data']
        expect(data).to be_nil
      end
    end

    context 'in "percentage" mode' do
      it 'shortens the text to the configured percentage' do
        expect { @checker.receive([event]) }.to change(Event, :count).by(1)
        summary = Event.last.payload['summary']
        expect(summary).not_to be_nil
        expect(summary.length.to_f / text.length.to_f).to be <= 0.3
      end
    end

    context 'in "sentences" mode' do
      before do
        @checker.options['mode'] = 'sentences'
        @checker.options['length'] = '3'
      end

      it 'shortens the text to the configured amount of sentences' do
        expect { @checker.receive([event]) }.to change(Event, :count).by(1)
        summary = Event.last.payload['summary']
        expect(summary).not_to be_nil
        expect(summary.split('.').length).to eq(3)
      end
    end
  end
end
