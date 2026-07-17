require "erb"
require "yaml"
require_relative "version"
require_relative "action"
require_relative "edit_engine"
require_relative "control_manifest"
require_relative "managed_files"
require_relative "module_descriptor"

module T40Starter
  # Computes the full set of install actions for a target application.
  #
  # The registry is glob-driven: every file under template/ maps to the same
  # relative path in the target. There are no hardcoded file lists, so
  # template content can evolve without installer changes.
  #
  #   *.t40erb                     => rendered with ERB (manifest, starter_version), suffix stripped
  #   db/migrate/NNN_name.rb       => db/migrate/<timestamp>_name.rb, skipped when any
  #                                   db/migrate/*_name.rb already exists
  #   everything else              => copy-if-absent (identical => skip, different => conflict)
  #
  # Marked edits come from lib/t40_starter/edits.yml via EditEngine.
  class Registry
    MIGRATION_PATTERN = %r{\Adb/migrate/(\d+)_(.+\.rb)\z}
    IGNORED_BASENAMES = %w[.DS_Store].freeze

    def initialize(manifest:, target:, starter_root: T40Starter.root, now: Time.now)
      @manifest = manifest
      @target = target
      @starter_root = starter_root
      @now = now
      @managed_files = ManagedFiles.new(target: target)
    end

    def template_dir = File.join(@starter_root, "template")

    def modules_dir = File.join(@starter_root, "modules")

    def edits_path = File.join(@starter_root, "lib", "t40_starter", "edits.yml")

    def actions
      @actions ||= file_actions + [ manifest_action ] + edit_actions
    end

    def conflicts = actions.select(&:conflict?)

    def changes = actions.select(&:change?)

    # Fail-closed module gating. Selecting a module that is missing from the
    # starter, or whose descriptor is not `status: available`, is a hard
    # preflight error.
    def module_errors
      descriptor_errors = ModuleDescriptor.validate_all(modules_dir)
      selection_errors = @manifest.selected_modules.filter_map do |name|
        descriptor = ModuleDescriptor.new(name: name, modules_dir: modules_dir)
        if !File.file?(descriptor.path)
          "module '#{name}' is not part of this starter release (missing modules/#{name}/module.yml)"
        elsif descriptor.status != "available"
          "module '#{name}' requires an approved, funded client requirement; " \
            "interface only in this release (see modules/#{name}/MODULE.md)"
        end
      end
      descriptor_errors + selection_errors
    end

    private
      def template_files
        return [] unless Dir.exist?(template_dir)

        Dir.glob("**/*", File::FNM_DOTMATCH, base: template_dir).sort.select do |relative|
          basename = File.basename(relative)
          next false if IGNORED_BASENAMES.include?(basename)

          File.file?(File.join(template_dir, relative))
        end
      end

      def file_actions
        migrations = []
        plain = []
        template_files.each do |relative|
          source_path = File.join(template_dir, relative)
          if relative.end_with?(".t40erb")
            content = render_erb(source_path)
            relative_target = relative.delete_suffix(".t40erb")
          else
            content = File.binread(source_path)
            relative_target = relative
          end
          if (match = relative_target.match(MIGRATION_PATTERN))
            migrations << { order: match[1].to_i, name: match[2], source: relative, content: content }
          else
            plain << plain_action(relative, relative_target, content)
          end
        end
        plain + migration_actions(migrations)
      end

      # The canonical manifest is starter-managed state. A changed selection is
      # an explicit edit in the plan (not a conflict), so the operator sees it
      # before apply replaces the previous selection.
      def manifest_action
        destination = File.join(@target, "t40-manifest.yml")
        content = @manifest.to_yaml
        if !File.exist?(destination)
          Action.new(type: :manifest, status: :create, target: "t40-manifest.yml",
                     source: "install manifest", content: content,
                     reason: "persist canonical installation selection")
        elsif File.binread(destination) == content.b
          Action.new(type: :manifest, status: :skip, target: "t40-manifest.yml",
                     source: "install manifest", content: content,
                     reason: "canonical installation selection already persisted")
        else
          Action.new(type: :manifest, status: :edit, target: "t40-manifest.yml",
                     source: "install manifest", content: content,
                     reason: "installation selection changed")
        end
      end

      def plain_action(relative_source, relative_target, content)
        destination = File.join(@target, relative_target)
        if !File.exist?(destination)
          Action.new(type: :file, status: :create, target: relative_target, source: relative_source,
                     content: content)
        elsif File.binread(destination) == content.b
          Action.new(type: :file, status: :skip, target: relative_target, source: relative_source,
                     reason: "identical content already present")
        elsif (managed = @managed_files.entry(relative_target))
          previous_source = managed["source_sha256"].to_s
          previous_install = managed["installed_sha256"].to_s
          desired = Digest::SHA256.hexdigest(content.b)
          current = Digest::SHA256.file(destination).hexdigest

          if desired == previous_source
            Action.new(type: :file, status: :project_owned, target: relative_target, source: relative_source,
                       content: content, reason: "project-owned changes preserved; starter content is unchanged")
          elsif current == previous_install
            Action.new(type: :file, status: :edit, target: relative_target, source: relative_source,
                       content: content, reason: "untouched starter-managed file has an available upgrade")
          else
            Action.new(type: :file, status: :conflict, target: relative_target, source: relative_source,
                       content: content, reason: "both the project and starter changed since the last install")
          end
        else
          Action.new(type: :file, status: :conflict, target: relative_target, source: relative_source,
                     reason: "existing file differs from the starter version")
        end
      end

      # Timestamps are strictly increasing in NNN order starting from now, so
      # foreign keys resolve in the same order the template declares.
      def migration_actions(migrations)
        base = @now.getutc
        migrations.sort_by { |migration| migration[:order] }.each_with_index.map do |migration, index|
          if migration_installed?(migration[:name])
            Action.new(type: :migration, status: :skip, target: "db/migrate/*_#{migration[:name]}",
                       source: migration[:source], reason: "migration already present in db/migrate")
          else
            timestamp = (base + index).strftime("%Y%m%d%H%M%S")
            Action.new(type: :migration, status: :create,
                       target: File.join("db", "migrate", "#{timestamp}_#{migration[:name]}"),
                       source: migration[:source], content: migration[:content])
          end
        end
      end

      def migration_installed?(name)
        directory = File.join(@target, "db", "migrate")
        return false unless Dir.exist?(directory)

        stem = Regexp.escape(name.delete_suffix(".rb"))
        pattern = /\A\d+_#{stem}\.rb\z/
        Dir.children(directory).any? { |entry| entry.match?(pattern) }
      end

      def render_erb(path)
        ERB.new(File.read(path), trim_mode: "-").result_with_hash(
          manifest: @manifest.to_h,
          starter_version: T40Starter::VERSION,
          controls: ControlManifest.new(manifest: @manifest, starter_root: @starter_root, now: @now).build["controls"]
        )
      rescue ScriptError, StandardError => error
        raise Error, "failed to render #{path}: #{error.class}: #{error.message}"
      end

      def edit_actions
        return [] unless File.file?(edits_path)

        EditEngine.new(edits_path).actions_for(@target)
      end
  end
end
