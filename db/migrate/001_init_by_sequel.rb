Sequel.migration do
  up do
    create_table :graph_nodes do
      primary_key :id
      Integer :parent_id, null: false
    end

    create_table :node_children do
      Integer :node_id,  null: false
      Integer :child_id, null: false
      primary_key [:node_id, :child_id]
    end

    create_table :messages do
      primary_key :id
      Integer  :node_id,      index: true, null: false
      String   :address,      size:  1024, null: false
      String   :type,         size:  32,   null: false
      String   :kind,         size:  32,   null: false
      String   :title,        null:  false
      String   :body,         text:  true, null: false
      String   :misc,         text:  true
      DateTime :created_at,   index: true, null: false
      DateTime :delivered_at
    end

    create_table :items do
      primary_key :id
      Integer  :message_id,  index: true, null: false
      String   :address,     size:  1024, null: false
      String   :type,        size:  32,   null: false
      String   :kind,        size:  32,   null: false
      String   :name,        null:  false
      String   :message,     text:  true, null: false
      String   :misc,        text:  true
      DateTime :received_at, index: true, null: false
    end
  end

  down do
    drop_table :graph_nodes, :node_children, :messages, :items
  end
end
