module CoreExtenstions
  module Hash
    module Compacting
      def compact
        self.select { |_, value| !value.nil? }
      end

      def compact!
        self.reject! { |_, value| value.nil? }
      end
    end
  end
end
