require 'bogo'
require 'tempfile'

class Bogo
  # Tempfile that will destroy itself when closed
  class EphemeralFile < Tempfile

    # Override to remove file after close
    def close
      super
      delete
    end

  end
end
