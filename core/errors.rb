# Errors is for application-specific errors

module BookclubErrors
  class AuthError < StandardError
    attr_reader :status_code
    attr_reader :msg

    def initialize(status_code, msg)
      @status_code, @msg = status_code, msg
      super(msg)
    end
  end

  class ShelfOpError < StandardError
    attr_reader :status_code
    attr_reader :msg

    def initialize(status_code, msg)
      @status_code, @msg = status_code, msg
      super(msg)
    end
  end

  class ProfileError < StandardError
    attr_reader :status_code
    attr_reader :msg

    def initialize(status_code, msg)
      @status_code, @msg = status_code, msg
      super(msg)
    end
  end
end
