require "erb"

# Root ProjectRazor namespace
module ProjectRazor
  module ModelTemplate
    # Root Model object
    # @abstract
    class UbuntuPreciseNoHostname < Ubuntu
      include(ProjectRazor::Logging)

      def initialize(hash)
        super(hash)
        # Static config
        @hidden          = false
        @name            = "ubuntu_precise_nohostname"
        @description     = "Ubuntu Precise Model (No hostname)"
        # State / must have a starting state
        @current_state   = :init
        # Image UUID
        @image_uuid      = true
        # Image prefix we can attach
        @image_prefix    = "os"
        # Enable agent brokers for this model
        @broker_plugin   = :agent
        @osversion       = 'precise_nohostname'
        @final_state     = :os_complete
        @req_metadata_hash = {
            "@root_password"   => {
                :default     => "test1234",
                :example     => "P@ssword!",
                :validation  => '^[\S]{8,}',
                :required    => true,
                :description => "root password (> 8 characters)"
            },
        }

        from_hash(hash) unless hash == nil
      end

      def node_ip_address
        "#{@ip_range_network}.#{(@ip_range_start..@ip_range_end).to_a[@counter - 1]}"
      end

    end
  end
end
