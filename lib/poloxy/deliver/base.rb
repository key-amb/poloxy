class Poloxy::Deliver::Base
  def initialize logger: nil
    @logger = logger
  end

  # @param message [Poloxy::DataModel::Message]
  def deliver message
    raise Poloxy::Error, 'Please override in subclass!'
  end
end
