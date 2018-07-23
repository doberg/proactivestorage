# frozen_string_literal: true

require "sdoc"

class RDoc::Generator::API < RDoc::Generator::SDoc # :nodoc:
  RDoc::RDoc.add_generator self

  def generate_class_tree_level(classes, visited = {})
    # Only process core extensions on the first visit and remove
    # Pro Active Storage duplicated classes that are at the top level
    # since they aren't nested under a definition of the `ProActiveStorage` module.
    if visited.empty?
      classes = classes.reject { |klass| pro_active_storage?(klass) }
      core_exts, classes = classes.partition { |klass| core_extension?(klass) }

      super.unshift([ "Core extensions", "", "", build_core_ext_subtree(core_exts, visited) ])
    else
      super
    end
  end

  private
    def build_core_ext_subtree(classes, visited)
      classes.map do |klass|
        [ klass.name, klass.document_self_or_methods ? klass.path : "", "",
            generate_class_tree_level(klass.classes_and_modules, visited) ]
      end
    end

    def core_extension?(klass)
      klass.name != "ActiveSupport" && klass.in_files.any? { |file| file.absolute_name.include?("core_ext") }
    end

    def pro_active_storage?(klass)
      klass.name != "ProActiveStorage" && klass.in_files.all? { |file| file.absolute_name.include?("pro_active_storage") }
    end
end
