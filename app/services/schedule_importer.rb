
class ScheduleImporter
  def initialize(path, extension)
    @path = path
    @extension = extension
  end

  def call
    case @extension
    when ".csv"
      read_csv
    when ".txt"
      read_text
    when ".xlsx", ".xls"
      read_spreadsheet
    when ".docx"
      read_word_document
    when ".pdf"
      read_pdf_document
    else
      raise ArgumentError, "Unsupported file format: #{@extension}"
    end
  end

  private

  def read_csv
    rows = CSV.read(@path, encoding: "bom|utf-8")
    spreadsheet_result(rows)
  end

  def read_text
    text_document_result(File.read(@path, encoding: "bom|utf-8"))
  end

  def read_spreadsheet
    spreadsheet = Roo::Spreadsheet.open(
      @path,
      extension: @extension.delete_prefix(".").to_sym
    )

    sheet = spreadsheet.sheet(0)
    last_row = sheet.last_row || 0

    rows = if last_row.positive?
             (1..last_row).map { |number| sheet.row(number) }
           else
             []
           end

    spreadsheet_result(rows)
  end

  def read_word_document
    document = Docx::Document.open(@path)

    if document.tables.any?
      rows = document.tables.first.rows.map do |row|
        row.cells.map { |cell| cell.text.to_s.strip }
      end

      spreadsheet_result(rows)
    else
      paragraphs = document.paragraphs.map(&:to_s)
      text_document_result(paragraphs.join("\n"))
    end
  end

  def read_pdf_document
    reader = PDF::Reader.new(@path)
    text = reader.pages.map(&:text).join("\n")

    result = text_document_result(text)

    if text.strip.empty?
      result[:notice] =
        "No selectable text was found. This PDF may be scanned or image-based."
    end

    result
  end

  def spreadsheet_result(rows)
    {
      headers: Array(rows.first).map { |value| value.to_s.strip },
      rows: rows.drop(1),
      document_text_mode: false,
      notice: nil
    }
  end

  def text_document_result(text)
    lines = text.to_s
                .lines
                .map(&:strip)
                .reject(&:blank?)

    {
      headers: ["Extracted text"],
      rows: lines.map { |line| [line] },
      document_text_mode: true,
      notice: nil
    }
  end
end
