require 'bogo'

module Bogo
  # Animal stylings on strings
  module AnimalStrings

    # Camel case string
    #
    # @param string [String]
    # @param leading_upcase [TrueClass, FalseClass] camel case first letter
    # @return [String]
    def camel(string, leading_upcase=true)
      head, tail = leading_upcase ? [nil, string] : string.split('_', 2)
      tail = tail.to_s.split('_').map do |k|
        "#{k.slice(0,1).upcase}#{k.slice(1,k.length)}"
      end.join
      [head, tail.empty? ? nil : tail].compact.join
    end

    # Snake case (underscore) string
    #
    # @param string [String]
    # @return [String]
    def snake(string)
      string.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').gsub('-', '_').downcase
    end

  end

end
