require "roo"
require "csv"
require "docx"
require "pdf-reader"

class ImportsController < ApplicationController
  SUPPORTED_FORMATS = %w[
    .xlsx
    .xls
    .csv
    .docx
    .txt
    .pdf
  ].freeze

  MAX_FILE_SIZE = 10.megabytes
  PREVIEW_LIMIT = 10

  def new
  end

  def create
    file = params[:file]

    if file.blank?
      redirect_to new_import_path,
                  alert: "Please select a schedule file."
      return
    end

    extension = File.extname(file.original_filename).downcase

    unless SUPPORTED_FORMATS.include?(extension)
      redirect_to new_import_path,
                  alert: "Please upload an XLSX, XLS, CSV, DOCX, TXT, or PDF file."
      return
    end

    if file.size > MAX_FILE_SIZE
      redirect_to new_import_path,
                  alert: "The file must be smaller than 10 MB."
      return
    end

    result = read_schedule_file(file.tempfile.path, extension)

    @headers = result[:headers]
    @detected_columns = HeaderDetector.detect(@headers)
    @rows = result[:rows].first(PREVIEW_LIMIT)
    @document_text_mode = result[:document_text_mode]
    @extraction_notice = result[:notice]

    render :preview

  rescue CSV::MalformedCSVError, EncodingError => e
    Rails.logger.warn(
      "Schedule parsing failed: #{e.class}: #{e.message}"
    )

    redirect_to new_import_path,
                alert: "The file could not be read. Check its format and encoding."

  rescue StandardError => e
    Rails.logger.error(
      "Schedule import failed: #{e.class}: #{e.message}"
    )

    redirect_to new_import_path,
                alert: "Could not read the schedule. Check that the file is valid."
  end

  private

  def read_schedule_file(path, extension)
    case extension
    when ".csv"
      rows = CSV.read(path, encoding: "bom|utf-8").map(&:to_a)
      spreadsheet_result(rows)

    when ".txt"
      text_document_result(File.read(path, encoding: "bom|utf-8"))

    when ".xlsx", ".xls"
      spreadsheet = Roo::Spreadsheet.open(
        path,
        extension: extension.delete_prefix(".").to_sym
      )

      sheet = spreadsheet.sheet(0)
      last_row = sheet.last_row || 0

      rows = if last_row.positive?
               (1..last_row).map { |number| sheet.row(number) }
             else
               []
             end

      spreadsheet_result(rows)

    when ".docx"
      read_word_document(path)

    when ".pdf"
      read_pdf_document(path)
    end
  end

  def spreadsheet_result(rows)
    headers = Array(rows.first).map { |value| value.to_s.strip }

    {
      headers: headers,
      rows: rows.drop(1),
      document_text_mode: false,
      notice: nil
    }
  end

  def read_word_document(path)
    document = Docx::Document.open(path)

    if document.tables.any?
      table = document.tables.first

      rows = table.rows.map do |row|
        row.cells.map { |cell| cell.text.to_s.strip }
      end

      spreadsheet_result(rows)
    else
      paragraphs = document.paragraphs.map(&:to_s)
      text_document_result(paragraphs.join("\n"))
    end
  end

  def read_pdf_document(path)
    reader = PDF::Reader.new(path)

    text = reader.pages.map(&:text).join("\n")
    result = text_document_result(text)

    if text.strip.empty?
      result[:notice] =
        "No selectable text was found. This PDF may be scanned or image-based."
    end

    result
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