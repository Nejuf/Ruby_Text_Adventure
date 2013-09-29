require 'ostruct'
require 'graph'

class Node < OpenStruct

	DEFAULTS = {
		:root => {:open => true},
		:room => {:open => true},
		:item => {:open => false},
		:player => {:open => true}
	}
  def initialize(parent, tag, defaults={}, &block)
	super()
	
	defaults.each {|k,v| send("#{k}=", v)}

	self.parent = parent
	self.parent.children << self unless parent.nil?
	self.tag = tag
	self.children = []
	
	#yield(self) if block_given?
	instance_eval(&block) unless block.nil?
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
  	Node.new(self, :player, DEFAULTS[:player], &block)
  end

  def self.root(&block)
  	Node.new(nil, :root, &block)
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

end


root = Node.root do
	room(:living_room) do
		self.exit_north = :kitchen
		self.exit_ease = :hall

		item(:cat, 'cat', 'sleeping', 'fuzzy') do
			item(:dead_mouse, 'mouse', 'dead', 'eaten')
		end

		item(:remote_control, 'remote', 'control') do
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
	end
end

puts root
root.save_graph
root.save_map