require_relative 'code_context'
require_relative 'method_context'
require_relative 'visibility_tracker'
require_relative '../ast/sexp_formatter'

module Reek
  module Context
    #
    # A context wrapper for any module found in a syntax tree.
    #
    # :reek:FeatureEnvy
    class ModuleContext < CodeContext
      attr_reader :visibility_tracker

      def initialize(context, exp)
        super

        @visibility_tracker = VisibilityTracker.new
      end

      # Register a child context. The child's parent context should be equal to
      # the current context.
      #
      # This makes the current context responsible for setting the child's
      # visibility.
      #
      # @param child [CodeContext] the child context to register
      def append_child_context(child)
        visibility_tracker.set_child_visibility(child)
        super
      end

      def defined_instance_methods(visibility: :public)
        each.select do |context|
          context.is_a?(Context::MethodContext) &&
            context.visibility == visibility
        end
      end

      def instance_method_calls
        each.
          grep(SendContext).
          select { |context| context.parent.class == MethodContext }
      end

      #
      # @deprecated use `defined_instance_methods` instead
      #
      def node_instance_methods
        local_nodes(:def)
      end

      def descriptively_commented?
        CodeComment.new(exp.leading_comment).descriptive?
      end

      # A namespace module is a module (or class) that is only there for namespacing
      # purposes, and thus contains only nested constants, modules or classes.
      #
      # However, if the module is empty, it is not considered a namespace module.
      #
      # @return true if the module is a namespace module
      def namespace_module?
        return false if exp.type == :casgn
        contents = exp.children.last
        contents && contents.find_nodes([:def, :defs], [:casgn, :class, :module]).empty?
      end

      def track_visibility(visibility, names)
        visibility_tracker.track_visibility children: instance_method_children,
                                            visibility: visibility,
                                            names: names
      end

      # FIXME: Move to VisibilityTracker
      VISIBILITY_MAP = { public_class_method: :public, private_class_method: :private }

      def track_singleton_visibility(visibility, names)
        return if names.empty?
        visibility = VISIBILITY_MAP[visibility]
        visibility_tracker.track_visibility children: singleton_method_children,
                                            visibility: visibility,
                                            names: names
      end

      def instance_method_children
        children.select(&:instance_method?)
      end

      def singleton_method_children
        children.select(&:singleton_method?)
      end

      def singleton_method?
        false
      end

      def instance_method?
        false
      end
    end
  end
end
