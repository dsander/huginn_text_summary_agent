module Agents
  class TextSummaryAgent < Agent
    include FormConfigurable

    no_bulk_receive!
    can_dry_run!
    cannot_be_scheduled!

    gem_dependency_check { defined?(Epitome) }

    description <<-MD
      The Text Summary Agent creates a summary of the provided text using the [epitome gem](https://github.com/McFreely/epitome)

      `data` text to summarize, use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) formatting construct the text based on the incoming event.

      `length` when `mode` is `percentage` (in decimal form) the summary length will be at most the configured percentage of the orignal text, if `mode` is `sentences` the summary will be X sentences long.

      `threshold`  is a value between 0.1 and 0.3, but 0.2 is considered to give the best results (and thus the default value).

      `merge` set to true to retain the received payload and update it with the extracted result

      `result_key` sets the key which contains the the extracted information.

      [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) formatting can be used in all options.
    MD

    def default_options
      {
        'mode' => 'percentage',
        'length' => '0.3',
        'data' => '{{data}}',
        'threshold' => '0.2',
        'merge' => 'true',
        'result_key' => 'summary',
      }
    end

    form_configurable :mode, type: :array, values: ['percentage', 'sentences']
    form_configurable :length
    form_configurable :threshold
    form_configurable :data, type: :text
    form_configurable :merge, type: :boolean
    form_configurable :result_key

    def validate_options
      errors.add(:base, "data needs to be present") if options['data'].blank?
      errors.add(:base, "length needs to be present") if options['length'].blank?
      errors.add(:base, "threshold needs to be present") if options['threshold'].blank?
    end

    def working?
      received_event_without_error?
    end

    def receive(incoming_events)
      interpolate_events(incoming_events) do |event|
        payload = boolify(interpolated['merge']) ? event.payload : {}
        payload.merge!(interpolated['result_key'] => summarize)

        create_event payload: payload
      end
    end

    def interpolate_events(events)
      events.each do |event|
        interpolate_with(event) do
          yield event
        end
      end
    end

    def summarize
      doc = Epitome::Document.new(interpolated['data'])
      corpus = Epitome::Corpus.new([doc])
      if interpolated['mode'] == 'percentage'
        ShortenToPercentage.new(corpus: corpus, interpolated: interpolated).run
      else
        corpus.summary(interpolated['length'].to_i, interpolated['threshold'].to_f)
      end
    end

    class ShortenToPercentage
      attr_reader :corpus, :interpolated, :summary

      def initialize(corpus:, interpolated:)
        @corpus = corpus
        @interpolated = interpolated
        @sentences = (interpolated['data'].split('.').length * interpolated['length'].to_f).round
        summarize!
      end

      def summarize!
        @summary = corpus.summary(@sentences, interpolated['threshold'].to_f)
      end

      def run
        if too_long?
          (@summary, _) = iterate(direction: -1, do_while: :too_long?)
        else
          (_, @summary) = iterate(direction: 1, do_while: :too_short?)
        end
        @summary
      end

      def too_short?
        !too_long?
      end

      def too_long?
        summary.length.to_f / interpolated['data'].length > interpolated['length'].to_f
      end

      def iterate(direction:, do_while:)
        previous_summary = nil
        while send(do_while)
          @sentences += direction
          break if @sentences == 0
          previous_summary = summary
          summarize!
          break if summary.empty?
        end
        return [summary, previous_summary]
      end
    end
  end
end
