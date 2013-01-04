module ProjectRazor
  module ModelTemplate

    class Redhat6NoHostname < Redhat
      include(ProjectRazor::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden      = false
        @name        = "redhat_6_nohostname"
        @description = "RedHat 6 Model (No hostname)"
        @osversion   = "6_nohostname"
       @req_metadata_hash = {
            "@root_password" => {
                :default     => "test1234",
                :example     => "P@ssword!",
                :validation  => '^[\S]{8,}',
                :required    => true,
                :description => "root password (> 8 characters)"
            },
        }

        from_hash(hash) unless hash == nil
      end
    end
  end
end
