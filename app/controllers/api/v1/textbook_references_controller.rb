# frozen_string_literal: true

module Api
  module V1
    class TextbookReferencesController < ApplicationController
      # GET /api/v1/textbooks/:textbook_code/kanjis
      def by_textbook
        @references = TextbookReference.by_textbook(params[:textbook_code]).includes(:kanji).ordered

        # Filter by chapter if provided
        @references = @references.by_chapter(params[:chapter]) if params[:chapter].present?

        render json: TextbookReferenceSerializer.new(@references, include: [:kanji]).serializable_hash
      end

      # GET /api/v1/kanjis/:kanji_id/textbooks
      def by_kanji
        @kanji = Kanji.find(params[:kanji_id])
        @references = @kanji.textbook_references.ordered

        render json: TextbookReferenceSerializer.new(@references).serializable_hash
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Kanji not found" }, status: :not_found
      end
    end
  end
end
