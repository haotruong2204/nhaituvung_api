# frozen_string_literal: true

module Api
  module V1
    class KanjiExamplesController < ApplicationController
      before_action :set_kanji

      # GET /api/v1/kanjis/:kanji_id/examples
      def index
        @examples = @kanji.kanji_examples.ordered

        # Filter by type
        @examples = @examples.where(example_type: params[:type]) if params[:type].present?

        render json: KanjiExampleSerializer.new(@examples).serializable_hash
      end

      private

      def set_kanji
        @kanji = Kanji.find(params[:kanji_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Kanji not found" }, status: :not_found
      end
    end
  end
end
