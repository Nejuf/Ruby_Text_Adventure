
class Player < Node

	def play
		loop do 
			do_look
			print "What now? "
			command(gets.chomp)
		end
	end

	%w{north south east west up down}.each do |dir|
		define_method("do_#{dir}") do
			do_go(dir)
		end

		define_method("do_#{dir[0]}") do
			do_go(dir)
		end
	end
	alias_method :do_get, :do_take
	alias_method :do_inv, :do_inventory
	alias_method :do_i, :do_inventory


	def command(words)
		ver, *words = words.split(' ')
		verb = "do_#{verb}"

		if respond_to?(verb)
			send(verb, *words)
		else
			puts "I don't know how to do that."
		end
	end

	def do_go(direction, *a)
		dest = get_room.send("exit_#{direction}")

		if dest.nil?
			puts "You can't go that way."
		else
			get_root.move(self, dest)
		end
	end

	def do_take(*thing)
		get_root.move(thing.join(' '), self)
	end

	def do_drop(*thing)
		move(thing.join(' '), get_room)
	end

	def open_close(thing, state)
		container = get_room.find(thing)
		return if container.nil?

		if container.open == state
			puts "It's already #{state ? 'open' : 'closed'}"
		else
			container.open = state
		end
	end

	def do_open(*thing)
		open_close(thing, true)
	end

	def do_close(*thing)
		open_close(thing, false)
	end

	def do_look(*a)
		puts "You are in #{get_room.tag}"
	end

	def do_inventory(*a)
		puts "You are carrying:"

		if children.empty?
			puts " * Nothing"
		else
			children.each do |c|
				puts " * #{c.name} (#{c.words.join(' ')})"
			end
		end
	end

	def do_put(*words)
		prepositions = [' in ', ' on ']

		prep_regex = Regexp.new("(#{prepositions.join('|')})")
		item_words, _, cont_words = words.join(' ').split(prep_regex)

		if cont_words.nil?
			puts "You want to put that where?"
			return
		end

		item = get_room.find(item_words)
		container = get_room.find(cont_words)

		return if item.nil? || container.nil?

		get_room.move(item, container)
	end
end