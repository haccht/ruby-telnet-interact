require 'io/console'
require 'net/telnet'

module Net
  class Telnet
    def interact!
      $stdin.raw!

      loop do
        rs, _ = IO.select([$stdin, @sock])
        rs.each do |fh|
          case fh
          when $stdin
            bs = ''
            begin
              bs = fh.read_nonblock(1)
              if bs == "\e"
                bs << fh.read_nonblock(3)
                bs << fh.read_nonblock(2)
              end
            rescue IO::WaitReadable
            end

            raise EOFError if bs == "\u001D" # <Ctrl-]>
            @sock.syswrite(bs)
          when @sock
            bs = fh.readpartial(1024)
            $stdout.syswrite(bs)
            @logproc.call(bs)
          end
        end
      end
    rescue EOFError
      self.close
      $stdout.puts "\r\n", "Conneciton closed by foreign host."
    ensure
      $stdin.cooked!
    end
  end
end
