class Node < OpenStruct
  def initialize(parent, tag)
	super
	
	self.parent = parent
	self.parent.children << self unless parent.nil?
	self.tag = tag
	self.children = []
	
	yield(self) if block_given?
  end
end