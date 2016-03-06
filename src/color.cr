module NyanSpec
    SPEC_COLORS = {
      pass: 32,
      fail: 31,
      pending: 33,
    };

    def self.color_me(color, str)
        "\u001b[" + SPEC_COLORS[color].to_s + 'm' + str + "\u001b[0m"
    end
end
