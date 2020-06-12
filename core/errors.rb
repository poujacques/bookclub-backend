class AuthError < StandardError
  attr_reader :status_code
  attr_reader :msg

  def initialize(status_code, msg)
    @status_code, @msg = status_code, msg
    super(msg)
  end
end
