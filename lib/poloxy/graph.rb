class Poloxy::Graph
  def initialize config: nil, logger: nil
    @config = config || Poloxy::Config.new
    @delimiter = @config.graph['delimiter']
    @logger = logger
    @data_model = Poloxy::DataModel.new
    @tree = lambda {
      nodes = @data_model.all 'GraphNode'
      if nodes.empty?
        @root = @data_model.spawn('GraphNode', label: 'root').save
        @root.children = []
        @root.group = '/'
        return { @root.id => @root }
      end

      leaves = @data_model.all 'NodeLeaf'
      tree = {}
      nodes.each do |n|
        leaves.select {|l| l.node_id == n.id}.each do |l|
          n.leaves[l.item] = l
        end
        tree[n.id] = n
        if n.parent_id > 0
          parent = tree[n.parent_id]
          parent.add_child n
          n.group = [ parent.group, n.label ].join(@delimiter) \
            .gsub(/#{@delimiter}+/, "#{@delimiter}")
        else
          @root = n
        end
      end
      tree
    }.call
  end

  # @param group [String] /path/to/group
  def node group=""
    labels = group2labels group
    return @root if labels.empty?
    _node = @root
    labels.each do |label|
      _node = _node.child_by_label label
      return nil unless _node
    end
    _node
  end

  # @param group [String] /path/to/group
  def node! group=""
    _node = @root
    labels = group2labels group
    if labels.empty?
      child = _node.child_by_label! 'default', @delimiter
      @tree[child.id] ||= child
      return child
    end
    labels.each do |label|
      _node = _node.child_by_label! label, @delimiter
      unless _node
        raise Poloxy::Error, "Invalid group! #{group}"
      end
      @tree[_node.id] ||= _node
    end
    _node
  end

  # @param node [Poloxy::DataModel::GraphNode]
  def update_node node
    return if node.parent_id == 0
    parent  = @tree[node.parent_id]
    updater = lambda do |level|
      parent.level = level
      parent.expire_at = [ parent.expire_at, node.expire_at ].max
      parent.save
      update_node parent
    end
    if node.level > parent.level
      updater.call node.level
    elsif node.level < parent.level
      children = parent.valid_children.select      {|n| n.level > node.level}
      leaves   = parent.valid_leaves.values.select {|l| l.level > node.level}
      list     = children.concat leaves
      if list.empty?
        updater.call node.level
      else
        max_level = list.map(&:level).max
        if max_level < parent.level
          updater.call max_level
        else
          update_ancestors parent, expire: node.expire_at
        end
      end
    else
      update_ancestors parent, expire: node.expire_at
    end
  end

  # @param message [Poloxy::DataModel::Message]
  def update_by_message message
    node = self.node! message.group
    node.update_leaf message, snooze: @config.message['default_snooze']
    self.update_node node
  end

  private

    def group2labels group
      group.gsub(/\s+/, '').sub(/^#{@delimiter}*(.+)#{@delimiter}*$/, '\1') \
        .split(/#{@delimiter}+/)
    end

    # Update timestamps towards root node
    def update_ancestors node, expire: Time.now
      node.expire_at = [ node.expire_at, expire ].max
      node.save
      if node.parent_id != 0
        update_ancestors @tree[node.parent_id], expire: node.expire_at
      end
    end
end
