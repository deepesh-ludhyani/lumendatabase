module NoticesHelper
  def form_partial_for(instance)
    "#{instance.type.tableize.singularize}_form"
  end

  def show_partial_for(instance)
    "#{instance.type.tableize.singularize}_show"
  end

  def works_partial_for(instance)
    "#{instance.type.tableize.singularize}_works"
  end

  def display_date_field(record, field)
    return unless (date = record.send(field))
    time_tag date, date.to_s(:simple)
  end

  def date_sent(notice)
    display_date_field(notice, :date_sent)
  end

  def date_received(notice)
    display_date_field(notice, :date_received)
  end

  def subject(notice)
    if notice.subject.present?
      notice.subject
    else
      'Unknown'
    end
  end

  def sent_via(notice)
    if notice.source.present?
      notice.source
    else
      'Unknown'
    end
  end

  def iso_countries
    CountrySelect::ISO_COUNTRIES_FOR_SELECT
  end

  def first_time_visitor_content
    Markdown.render(t('first_time_visitor'))
  end

  def label_for_url_input(url_type, notice)
    case url_type
    when :infringing_urls
      infringing_url_label(notice)
    when :copyrighted_urls
      copyrighted_url_label(notice)
    else
      raise "Unknown url_type: #{url_type}"
    end
  end

  def can_see_full_notice_version?(notice)
    return true if can?(:view_full_version, notice)

    TokenUrl.valid?(params[:access_token], notice)
  end

  def permanent_url_full_notice(notice)
    token_url = permanent_token_url(notice)

    if token_url
      return notice_url(
        notice,
        access_token: token_url.token,
        host: Chill::Application.config.site_host
      )
    end

    false
  end

  def with_redacted_urls(text)
    redacted_text = text.gsub(
      %r{(http[s]?://[w]*[\.]*[^/|$]*)(\S*)},
      '\1/[REDACTED]'
    )

    redacted_text
  end

  private

  def infringing_url_label(notice)
    case notice
    when ::DMCA, ::Trademark
      'Allegedly Infringing URL'
    when ::PrivateInformation
      'URL with private information'
    when ::CourtOrder
      'Targeted URL'
    when ::DataProtection, ::LawEnforcementRequest
      'URL mentioned in request'
    when ::Defamation
      'Allegedly Defamatory URL'
    when ::Other
      'Problematic URL'
    end
  end

  def copyrighted_url_label(notice)
    case notice
    when ::DMCA, ::Other
      'Original Work URL'
    when ::LawEnforcementRequest
      'URL of original work'
    end
  end

  def permanent_token_url(notice)
    TokenUrl.find_by(
      notice: notice,
      user: current_user,
      valid_forever: true
    )
  end
end
