# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include ApiResponse

      respond_to :json

      before_action :set_locale

      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
      rescue_from ActionController::ParameterMissing, with: :handle_bad_request
      rescue_from StandardError, with: :handle_internal_error if Rails.env.production?

      private

      def set_locale
        I18n.locale = params[:locale] || request.headers["Accept-Language"]&.split(",")&.first || I18n.default_locale
      end

      def handle_not_found exception
        not_found(exception.message)
      end

      def handle_record_invalid exception
        unprocessable_entity(exception.record)
      end

      def handle_bad_request exception
        bad_request(exception.message)
      end

      def handle_internal_error exception
        Rails.logger.error("Internal Error: #{exception.class} - #{exception.message}")
        Rails.logger.error(exception.backtrace.join("\n"))

        internal_error
      end
    end
  end
end
