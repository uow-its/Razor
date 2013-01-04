module ProjectRazor
  module ModelTemplate

    class Redhat5 < Redhat
      include(ProjectRazor::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden      = false
        @name        = "redhat_5"
        @description = "RedHat 5 Model"
        @osversion   = "5"

        from_hash(hash) unless hash == nil
      end
    end
  end
end
