module Localmail
  # One captured email, rebuilt from its stored raw source, with the parts the inbox
  # renders exposed as UTF-8 strings.
  class Message
    attr_reader :id, :mail

    delegate :subject, :from, :to, :cc, :bcc, :date, to: :mail

    def initialize(id, raw)
      @id = id
      @mail = Mail.read_from_string(raw)
    end

    def html_body
      body_for("text/html")
    end

    def preview_html
      return if html_body.nil?

      %(<base target="_blank">#{html_body})
    end

    def text_body
      body_for("text/plain")
    end

    def raw
      as_utf8(mail.to_s, mail.charset)
    end

    private

    def body_for(mime_type)
      part = part_for(mime_type)
      return if part.nil?

      as_utf8(part.body.decoded, part.charset)
    end

    def part_for(mime_type)
      return mail if !mail.multipart? && mail.mime_type == mime_type

      mail.all_parts.find { |part| part.mime_type == mime_type }
    end

    # Quoted-printable and base64 bodies decode to ASCII-8BIT. Re-tag with the part's own
    # charset before it reaches a UTF-8 view, or ERB raises on concatenation.
    def as_utf8(string, charset)
      string.dup
            .force_encoding(charset.presence || Encoding::UTF_8)
            .encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    rescue ArgumentError
      string.dup.force_encoding(Encoding::UTF_8).scrub
    end
  end
end
