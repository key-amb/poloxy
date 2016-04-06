class MForwd::Deliver::Base
  def initialize logger: nil
    @logger = logger
  end

  # @param message [MForwd::Message]
  def deliver message
    raise MForwd::Error, 'Please override in subclass!'
  end
end
