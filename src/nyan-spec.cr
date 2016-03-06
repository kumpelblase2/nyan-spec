require "./nyan-spec/*"
require "spec/formatter"
require "ncurses/lib_ncurses"
require "math"
require "./color"

module NyanSpec
  def self.init
      if (s = Spec).responds_to?(:"formatter=")
          s.formatter = NyanFormatter.new
      elsif (s = Spec).responds_to?(:"formatters")
          s.formatters[0] = NyanFormatter.new
      else
          raise "Could not find a way to attach formatter."
      end
  end

  class Stats
    @stats = {
        success: 0,
        pending: 0,
        fail: 0,
        error: 0
    }

    def add(result)
        @stats[result.kind] = @stats[result.kind] + 1
    end

    def get(kind)
        @stats[kind]
    end

    def has_failed?
        @stats[:fail] > 0
    end

    def has_pending?
        @stats[:pending] > 0
    end

    def has_success?
        @stats[:success] > 0
    end
  end

  class NyanFormatter < Spec::Formatter
    ESCAPE_SEQUENCE = "\033["

    def initialize(@size = 11)
        @width = init_screen

        @colorIndex = 0
        @number_of_lines = 4
        @colors = generate_colors
        @scoreboard_width = 4
        @tick = false
        @trajectories = Array.new(4) do |arr|
            [] of String
        end

        @trajectory_width_max = @width - @size
        @stats = Stats.new
    end

    def report(result)
        @stats.add(result)
        draw
    end

    def draw
        append_rainbow
        draw_scoreboard
        draw_rainbow
        draw_nyancat
        @tick = !@tick
    end

    def finish
        @number_of_lines.times do |i|
            write "\n"
        end
    end

    def init_screen
        src = LibNCurses.initscr
        width = LibNCurses.getmaxx(src)
        LibNCurses.endwin
        width
    end

    def generate_colors
        colors = [] of Float64
        pi3 = (Math::PI / 3).floor
        (6 * 7).times do |i|
            n = i * (1.0 / 6)
            r = (3 * Math.sin(n) + 3).floor
            g = (3 * Math.sin(n + 2 * pi3) + 3).floor
            b = (3 * Math.sin(n + 4 * pi3) + 3).floor
            colors << (36 * r + 6 * g + b + 16)
        end

        colors
    end

    def append_rainbow
        segment = @tick ? '_' : '-'
        rainbowified = rainbowify segment
        @number_of_lines.times do |i|
            trajectory = @trajectories[i]
            trajectory.shift if trajectory.size >= @trajectory_width_max
            trajectory << rainbowified
        end
    end

    def draw_scoreboard
        draw_with_color = ->(color : Symbol, n : Int32){
            write ' '
            write NyanSpec.color_me(color, n.to_s)
            write "\n"
        }

        draw_with_color.call(:pass, @stats.get(:success) || 0)
        draw_with_color.call(:fail, @stats.get(:fail) || 0)
        draw_with_color.call(:pending, @stats.get(:pending) || 0)
        write "\n"
        cursor_up @number_of_lines
    end

    def draw_rainbow
        @trajectories.each do |lines|
            write escape(@scoreboard_width.to_s + 'C')
            write lines.join("")
            write "\n"
        end

        cursor_up @number_of_lines
    end

    def draw_nyancat
        start_width = @scoreboard_width + @trajectories[0].size
        dist = escape(start_width.to_s + 'C')
        padding = ""
        write dist
        write "_,------,"
        write "\n"

        write dist
        padding = @tick ? "  " : "   "
        write "_|" + padding + "/\\_/\\ "
        write "\n"

        write dist
        padding = @tick ? "_" : "__"
        tail = @tick ? "~" : "^"
        write tail + '|' + padding + face + ' '
        write "\n"

        write dist
        padding = @tick ? " " : "  "
        write padding + "\"\" \"\" "
        write "\n"

        cursor_up @number_of_lines
    end

    def face
        case @stats
            when .has_failed?
                "( x .x)"
            when .has_pending?
                "( o .o)"
            when .has_success?
                "( ^ .^)"
            else
                "( - .-)"
        end
    end

    def cursor_up(lines)
        write escape(lines.to_s + 'A')
    end

    def rainbowify(str)
        color = @colors[@colorIndex % @colors.size]
        @colorIndex += 1
        escape("38;5;" + color.to_s + 'm') + str + escape("0m")
    end

    def escape(str)
        ESCAPE_SEQUENCE + str
    end

    def write(str)
        print str
    end
  end
end
