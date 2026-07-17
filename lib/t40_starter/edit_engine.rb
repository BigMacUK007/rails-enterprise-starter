require "yaml"
require_relative "version"
require_relative "action"

module T40Starter
  # Applies the marked-edit definitions from edits.yml.
  #
  # Every block is fenced by marker comments (its first and last lines).
  # Rules:
  #   - block present and identical            => :noop
  #   - markers present but content differs    => :edit (replace between markers)
  #   - markers absent, anchor found (or EOF)  => :edit (insert after anchor)
  #   - anchor line missing / file missing     => :conflict
  #
  # Inserted blocks are re-indented to the anchor's indentation plus one
  # level (two spaces); EOF appends keep the block's own indentation. The
  # generated application must pass rubocop-rails-omakase, whose enabled
  # Layout/CommentIndentation cop rejects column-zero marker comments inside
  # a class or block body.
  class EditEngine
    INDENT_STEP = "  "

    Edit = Struct.new(:file, :section, :anchor, :block, keyword_init: true)

    def initialize(edits_path)
      @edits_path = edits_path
    end

    def edits
      @edits ||= begin
        data = YAML.safe_load_file(@edits_path)
        raise Error, "edits file is not a YAML mapping: #{@edits_path}" unless data.is_a?(Hash)

        Array(data["edits"]).map do |entry|
          Edit.new(
            file: entry.fetch("file"),
            section: entry.fetch("section"),
            anchor: entry.fetch("anchor"),
            block: entry.fetch("block")
          )
        end
      end
    end

    def actions_for(target_dir)
      edits.map { |edit| action_for(edit, target_dir) }
    end

    def action_for(edit, target_dir)
      path = File.join(target_dir, edit.file)
      return conflict(edit, "target file missing: #{edit.file}") unless File.file?(path)

      original = File.read(path)
      lines = original.lines
      block_lines = edit.block.split("\n")
      begin_marker = block_lines.first.strip
      end_marker = block_lines.last.strip
      begin_index = lines.index { |line| line.strip == begin_marker }
      end_index = lines.index { |line| line.strip == end_marker }

      if begin_index && end_index
        replace_between_markers(edit, lines, block_lines, begin_index, end_index)
      elsif begin_index || end_index
        conflict(edit, "malformed t40:#{edit.section} markers in #{edit.file} (found one marker without the other)")
      elsif edit.anchor == "EOF"
        append_at_eof(edit, original, block_lines)
      else
        insert_after_anchor(edit, lines, block_lines)
      end
    end

    private
      def replace_between_markers(edit, lines, block_lines, begin_index, end_index)
        if end_index < begin_index
          return conflict(edit, "t40:#{edit.section} markers are out of order in #{edit.file}")
        end

        indent = lines[begin_index][/\A[ \t]*/]
        desired = render_block(block_lines, indent)
        current = lines[begin_index..end_index].join
        if current == desired
          build(edit, :noop, nil, "t40:#{edit.section} block already present")
        else
          content = (lines[0...begin_index] + [ desired ] + rest_of(lines, end_index + 1)).join
          build(edit, :edit, content, "replace existing t40:#{edit.section} block")
        end
      end

      def append_at_eof(edit, original, block_lines)
        base = original.dup
        base << "\n" unless base.empty? || base.end_with?("\n")
        content = base + render_block(block_lines, "")
        build(edit, :edit, content, "append t40:#{edit.section} block at end of file")
      end

      def insert_after_anchor(edit, lines, block_lines)
        anchor_index = lines.index { |line| line.strip == edit.anchor.strip }
        return conflict(edit, "anchor not found in #{edit.file}: #{edit.anchor.inspect}") if anchor_index.nil?

        indent = lines[anchor_index][/\A[ \t]*/] + INDENT_STEP
        desired = render_block(block_lines, indent)
        content = (lines[0..anchor_index] + [ desired ] + rest_of(lines, anchor_index + 1)).join
        build(edit, :edit, content, "insert t40:#{edit.section} block after anchor")
      end

      def rest_of(lines, index)
        lines[index..] || []
      end

      def render_block(block_lines, indent)
        block_lines.map { |line| line.empty? ? "\n" : "#{indent}#{line}\n" }.join
      end

      def conflict(edit, reason)
        build(edit, :conflict, nil, reason)
      end

      def build(edit, status, content, reason)
        Action.new(
          type: :edit,
          status: status,
          target: edit.file,
          source: "edits.yml##{edit.section}",
          content: content,
          reason: reason
        )
      end
  end
end
