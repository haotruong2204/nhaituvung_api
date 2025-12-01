# frozen_string_literal: true

module ApiResponse
  extend ActiveSupport::Concern

  def response_success data = {}, message: I18n.t("api.common.success"), status: :ok, meta: {}
    data = normalize_data(data)
    body = { success: true, code: status_code(status), message: message, data: data }
    body[:meta] = meta if meta.present?
    render status: status, json: body
  end

  def response_error errors = {}, message: I18n.t("api.common.fail"), status: :bad_request
    body = { success: false, code: status_code(status), message: message, errors: errors }
    render status: status, json: body
  end

  def bad_request message = I18n.t("api.error.bad_request"), errors: {}
    response_error(errors, message: message, status: :bad_request)
  end

  def unauthorized message = I18n.t("api.error.unauthorized")
    response_error({}, message: message, status: :unauthorized)
  end

  def forbidden message = I18n.t("api.error.forbidden")
    response_error({}, message: message, status: :forbidden)
  end

  def not_found message = I18n.t("api.error.not_found")
    response_error({}, message: message, status: :not_found)
  end

  def unprocessable_entity entity_or_message = nil, message: I18n.t("api.error.unprocessable_entity")
    if entity_or_message.respond_to?(:errors) && entity_or_message.errors.any?
      errors = format_errors(entity_or_message.errors)
      message = entity_or_message.errors.full_messages.first
      response_error(errors, message: message, status: :unprocessable_entity)
    elsif entity_or_message.is_a?(String)
      response_error({}, message: entity_or_message, status: :unprocessable_entity)
    else
      response_error({}, message: message, status: :unprocessable_entity)
    end
  end

  def internal_error message = I18n.t("api.error.internal_error")
    response_error({}, message: message, status: :internal_server_error)
  end

  private

  def normalize_data data
    case data
    when Hash
      data.dig(:resource, :data) || data
    when ActiveRecord::Relation, ActiveRecord::Base, Array
      data.as_json
    else
      data
    end
  end

  def format_errors errors
    errors.details.transform_values do |details|
      details.map { |d| d[:error] }
    end
  end

  def status_code status_symbol
    Rack::Utils.status_code(status_symbol)
  end
end
