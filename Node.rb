require 'ostruct'
require 'graph'
require 'yaml'
require_relative 'player'

class Node < OpenStruct

	DEFAULTS = {
		:root => {:open => true},
		:room => {:open => true},
		:item => {:open => false},
		:player => {:open => true}
	}
  def initialize(parent=nil, tag=nil, defaults={}, &block)#bug in YAML requires all params to have default value
	super()
	
	defaults.each {|k,v| send("#{k}=", v)}

	self.parent = parent
	self.parent.children << self unless parent.nil?
	self.tag = tag
	self.children = []
	
	#yield(self) if block_given?
	instance_eval(&block) unless block.nil?
  end

  def init_with(c)
  	c.map.keys.each do |k|
  		instance_variable_set("@#{k}", c.map[k])
  	end

  	@table.keys.each do |k|
  		new_ostruct_member(k)
  	end
  end

  def self.save(node, file='save.yaml')
  	File.open(file, 'w+') do |f|
  		f.puts node.to_yaml
  	end
  end

  def self.load(file='save.yaml')
  	YAML::load_file(file)
  end

  def room(tag, &block)
  	Node.new(self, tag, DEFAULTS[:room], &block)
  end

  def item(tag, name, *words, &block)
  	i = Node.new(self, tag, DEFAULTS[:item])
  	i.name = name
  	i.words = words
  	i.instance_eval(&block) if block_given?
  end

  def player(&block)
  	Player.new(self, :player, DEFAULTS[:player], &block)
  end

  def self.root(&block)
  	Node.new(nil, :root, &block)
  end

  def ancestors(list=[])
  	if parent.nil?
  		return list
  	else
  		list << parent
  		return parent.ancestors(list)
  	end
  end

  def move(thing, to, check=true)
  	item = find(thing)
  	dest = find(to)

  	return if item.nil?
  	if check && item.hidden?
  		puts "You can't get to that right now."
  		return
  	end

  	return if dest.nil?
  	if check && (dest.hidden? || dest.open == false)
  		puts "You can't put that there."
  		return
  	end

  	if dest.ancestors.include?(item)
  		puts "Are you trying to destroy the universe?"
  		return
  	end

  	item.parent.children.delete(item)
  	dest.children << item
  	item.parent = dest
  end

  def get_room
  	if parent.tag == :root
  		return self
  	else
  		return parent.get_room
  	end
  end

  def get_root
  	if tag == :root || parent.nil?
  		return self
  	else
  		return parent.get_root
  	end
  end

  def hidden?
  	if parent.tag == :root
  		return false
  	elsif parent.open == false
  		return true
  	else
  		return parent.hidden?
  	end
  end
  		
  def move(thing, to, check=true)
  	item = find(thing)
  	dest = find(to)

  	return if item.nil?
  	if check && item.hidden?
  		puts "You can't get to that right now."
  		return
  	end

  	return if dest.nil?
  	if check && (dest.hidden? || dest.open == false)
		puts "You can't put that there."
		return
	end

	item.parent.children.delete(item)
	dest.children << item
	item.parent = dest
end

  def find(thing)
  	case thing
  	when Symbol
  		find_by_tag(thing)
  	when String
  		find_by_string(thing)
  	when Node
  		thing
  	end
  end

  def find_by_tag(tag)
  	return self if self.tag == tag

  	children.each do |c|
  		res = c.find_by_tag(tag)
  		return res unless res.nil?
  	end

  	return nil
  end

  def find_by_name(words, nodes=[])
  	words = words.split unless words.is_a?(Array)
  	nodes << self if words.include?(name)

  	children.each do |c|
  		c.find_by_name(words, nodes)
  	end

  	return nodes
  end

  def find_by_string(words)
  	words = words.split unless words.is_a?(Array)
  	nodes = find_by_name(words)

  	if nodes.empty?
  		puts "I don't see that here."
  		return nil
  	end

  	#Score the nodes by the number of matching adjectives
  	nodes.each do |i|
  		i.search_score = (words & i.words).length
  	end

  	#Sort the score so that highest scores are at the beginning of th list
  	nodes.sort! do |a,b|
  		b.search_score <=> a.search_score
  	end

  	#Remove any nodes with a search score less than the score of the first item
  	nodes.delete_if do |i|
  		i.search_score < nodes.first.search_score
  	end

  	#Interpret the results
  	if nodes.length == 1
  		return nodes.first
  	else
  		puts "Which item do you mean?"
  		nodes.each do |i|
  			puts " * #{i.name} (#{i.words.join(', ')})"
  		end

  		return nil
  	end
  end

  def to_s(verbose=false, indent='')
  	bullet = if parent && parent.tag == :root
  		'#'
  	elsif tag == :player
  		'@'
  	elsif tag == :root
  		'>'
  	elsif open == true
  		'O'
  	else
  		'*'
  	end

  	str = "#{indent}#{bullet} #{tag}\n"
  	if verbose
  		self.table.each do |k,v|
  			if k == :children
  				str << "#{indent+'  '}#{k}=#{v.map(&:tag)}\n"
  			elsif v.is_a? (Node)
  				str << "#{indent+'  '}#{k}=#{v.tag}\n"
  			else
  				str << "#{indent+'  '}#{k}=#{v}\n"
  			end
  		end
  	end
  	
  	children.each do |c|
  		str << c.to_s(verbose, indent + '  ')
  	end

  	return str
  end		
  			

  def graph(gr=Graph.new)
  	gr.edge tag.to_s, parent.tag.to_s unless parent.nil?
  	gr.node_attribs << gr.filled

  	if tag == :player || tag == :root
  		gr.tomato << gr.node(tag.to_s)
  	elsif parent && parent.tag == :root
  		gr.mediumspringgreen << gr.node(tag.to_s)
  	end

  	children.each{|c| c.graph(gr)}
  	return gr
  end

  def save_graph
  	p graph
  	graph.save 'graph'#, 'svg'

  	#{}`svg2png graph.svg graph.png`
    #{}`open graph.png`
  end
  			
  def map(gr=Graph.new)
  	if parent && parent.tag == :root
  		methods.grep(/^exit_[a-z]+(?!=)$/) do|e|
        dir = e.to_s.split(/_/).last.split(//).first
        gr.edge(tag.to_s, send(e).to_s).label(dir)
	    end
	end

	children.each{|c| c.map(gr)}
	return gr
  end

  def save_map
    map.save 'map'#, 'svg'
    #{}`svg2png map.svg map.png`
    #{}`open map.png`
  end

  def script(key, *args)
  	if respond_to?("script_#{key}")
  		return eval(self.send("script_#{key}"))
  	else
  		return true
  	end
  end

end


root = Node.root do
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

puts root
root.save_graph
root.save_map

loop do 
	player = root.find(:player)
	player.do_look

	print "What now? "
	input = gets.chomp
	verb = input.split(' ').first

	case verb
	when "load"
		root = Node.load
		puts "Loaded"
	when "save"
		Node.save(root)
		puts "Saved"
	when "quit"
		puts "Goodbye!"
		exit
	else
		player.command(input)
	end
end
