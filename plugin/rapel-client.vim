" rapel-client.vim - Connect to a Rapel REPL Server
" Author:           Dominic Muller
" Version:          0.1

if exists("g:loaded_rapel_client")
  finish
endif

let g:loaded_rapel_client = 1

ruby << EOF

require 'json'
require 'socket'

module RapelClient

  def self.connect
    $server = TCPSocket.new('localhost', 8091)
  rescue Errno::ECONNREFUSED
    puts "No Rapel server found"
  end

  def self.send_exp(exp)
    raise "No Rapel server found" unless $server
    $server.puts({:op => "eval", :code => exp}.to_json)
    JSON.parse($server.gets.chomp)["result"]
  rescue
    puts $!.inspect
  end

  def self.last_line_of_current_selection
    Vim.evaluate("getpos(\"'>\")[1]")
  end

  def self.current_selection
    start_line, start_column = Vim.evaluate("getpos(\"'<\")[1:2]")
    end_line, end_column = Vim.evaluate("getpos(\"'>\")[1:2]")
    lines = Vim.evaluate("getline(#{start_line}, #{end_line})")
    lines[-1] = lines[-1][0..(end_column-1)]  # trim end of last line
    lines[0] = lines[0][(start_column-1)..-1] # trim beginning of first line
    lines.join("\n")
  end

  def self.send_current_selection
    expression = RapelClient.current_selection
    RapelClient.send_exp(expression)
  end

  def self.send_and_print_below
    line_number = RapelClient.last_line_of_current_selection
    expression = RapelClient.current_selection
    result = RapelClient.send_exp(expression)
    Vim::Buffer.current.append(line_number, "\#=> " + result)
  end
end

EOF

ruby RapelClient.connect
