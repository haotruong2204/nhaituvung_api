# frozen_string_literal: true

module Api
  module V1
    class KanjisController < ApplicationController
      before_action :set_kanji, only: [:show, :ui_format]

      # GET /api/v1/kanjis
      def index
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 20).to_i

        kanjis_query = filtered_kanjis
        total_count = kanjis_query.count

        @kanjis = kanjis_query.limit(per_page).offset((page - 1) * per_page)

        options = {
          meta: {
            current_page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          },
          include: params[:include]&.split(",")
        }

        render json: KanjiSerializer.new(@kanjis, options).serializable_hash
      end

      # GET /api/v1/kanjis/:id
      def show
        options = { include: params[:include]&.split(",") || [:kanji_examples, :textbook_references] }

        render json: KanjiSerializer.new(@kanji, options).serializable_hash
      end

      # GET /api/v1/kanjis/:id/ui
      # Returns data in the exact format expected by the UI
      def ui_format
        cache_key = "kanji_ui_format:#{@kanji.character}"

        cached_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          KanjiUiSerializer.new(@kanji).as_json
        end

        # Set cache headers for CDN and browser
        expires_in 1.hour, public: true

        render json: cached_data
      end

      # GET /api/v1/kanjis/search
      def search
        query = params[:q]
        return render json: { error: "Query parameter required" }, status: :bad_request if query.blank?

        @kanjis = Kanji.where("meaning LIKE ? OR `character` = ?", "%#{query}%", query).limit(50)

        render json: KanjiSerializer.new(@kanjis).serializable_hash
      end

      private

      def set_kanji
        @kanji = Kanji.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Kanji not found" }, status: :not_found
      end

      def filtered_kanjis
        kanjis = Kanji.all

        # Filter by JLPT level
        kanjis = kanjis.by_jlpt(params[:jlpt_level]) if params[:jlpt_level].present?

        # Filter by grade
        kanjis = kanjis.by_grade(params[:grade]) if params[:grade].present?

        # Filter by stroke count
        kanjis = kanjis.by_stroke_count(params[:stroke_count]) if params[:stroke_count].present?

        # Sort
        case params[:sort]
        when "frequency"
          kanjis.ordered_by_frequency
        when "stroke_count"
          kanjis.order(stroke_count: :asc)
        else
          kanjis.order(character: :asc)
        end
      end
    end
  end
end
