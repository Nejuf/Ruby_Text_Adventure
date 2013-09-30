require_relative 'node'

class Game

	attr_accessor :root
	
	def initalize
		@root = Node.root do
			room(:living_room) do
				self.exit_north = :kitchen
				self.exit_ease = :hall

				item(:cat, 'cat', 'sleeping', 'fuzzy') do
					self.script_take = <<-SCRIPT
						if get_room.find(:cat).find(:dead_mouse)
							puts "The cat makes a horrifying noise and throws up a dead mouse."
							get_room.move(:dead_mouse, get_room, false)
						end

						puts "The cat refused to be picked up (how degrading!)"
						return false
					SCRIPT

					self.script_control = <<-SCRIPT
						puts "The cat sits upright, awaiting your command."
						return true
					SCRIPT

					self.desc = <<-DESC
						A pumpkin-colored long-haired cat.
					DESC

					self.presence = <<-PRES
						A cat dozes lazily here.
					PRES

					item(:dead_mouse, 'mouse', 'dead', 'eaten')
				end

				item(:remote_control, 'remote', 'control') do
					self.script_accept = <<-SCRIPT
						if [:new_batteries, :old_batteries].include?(args[0].tag) && children.empty?
							return true
						elsif !children.empty?
							puts "There are already batteries in the remote."
							return false
						else
							puts "That won't fit into the remote."
							return false
						end
					SCRIPT
							
					self.script_use = <<-SCRIPT
						if !find(:new_batteries)
							puts "The remote doesn't seem to work."
							return
						end

						if args[0].tag == :cat 
							args[0].script('control')
							return
						else
							puts "The remote doesn't seem to work with that."
							return
						end
					SCRIPT

					item(:dead_batteries, 'batteries', 'dead', 'AA')
				end
			end

			room(:kitchen) do
				self.exit_south = :living_room

				player do
					item(:ham_sandwich, 'sandwich', 'ham')
				end

				item(:drawer, 'drawer', 'kitchen') do
					item(:new_batteries, 'batteries', 'new', 'AA')
				end
			end

			room(:hall) do
				self.exit_west = :living_room

				self.script_enter = <<-SCRIPT
					puts "A forcefield stops you from entering the hall."
					return false
				SCRIPT
			end
		end
	end

	class String
		def word_wrap(width=80)
			#Replace newlines with spaces
			gsub(/\n/, ' ').

			#Replace more than one space with a single space
			gsub(/\s+/, ' ').

			#Replace spaces at the beginning of the string with nothing
			gsub(/^\s+/, '').

			#This one is hard to read. Replace with any amount of space
			#after it with that punctuation and two spaces
			gsub(/([\.\!\?]+)(\s+)?/, '\1  ').

			# Similar to the call above, except replace commas
		    # with a comma and one space
		    gsub(/\,(\s+)?/, ', ').

		    # The meat of the method, replace between 1 and width
		    # characters followed by whitespace or the end of the
		    # line with that string and a newline.  This works
		    # because regular expression engines are greedy,
		    # they'll take as many characters as they can.
		    gsub(%r[(.{1,#{width}})(?:\s|\z)], "\\1\n")
		end
	end

	def debug
		puts @root
		@root.save_graph
		@root.save_map
	end

	def play
		loop do 
			player = @root.find(:player)
			player.do_look

			print "What now? "
			input = gets.chomp
			verb = input.split(' ').first

			case verb
			when "load"
				@root = Node.load
				puts "Loaded"
			when "save"
				Node.save(@root)
				puts "Saved"
			when "quit"
				puts "Goodbye!"
				exit
			else
				player.command(input)
			end
		end
	end
end

game = Game.new
game.play