require_relative 'code_context'

module Reek
  module Context
    #
    # A context wrapper for any method definition found in a syntax tree.
    #
    class MethodContext < CodeContext
      attr_accessor :visibility
      attr_reader :refs

      def initialize(context, exp)
        @visibility = :public
        super
      end

      def references_self?
        exp.depends_on_instance?
      end

      def uses_param?(param)
        local_nodes(:lvar).find { |node| node.var_name == param.to_sym }
      end

      # :reek:FeatureEnvy
      def unused_params
        exp.arguments.select do |param|
          next if param.anonymous_splat?
          next if param.marked_unused?
          !uses_param? param.plain_name
        end
      end

      def uses_super_with_implicit_arguments?
        (body = exp.body) && body.contains_nested_node?(:zsuper)
      end

      def default_assignments
        @default_assignments ||=
          exp.parameters.select(&:optional_argument?).map(&:children)
      end

      def singleton_method?
        false
      end

      def instance_method?
        true
      end

      # Was this method defined with an instance method-like syntax?
      def defined_as_instance_method?
        true
      end

      def module_function?
        visibility == :module_function
      end

      # @return [Boolean] If the visibility is public or not.
      def non_public_visibility?
        visibility != :public
      end
    end
  end
end
