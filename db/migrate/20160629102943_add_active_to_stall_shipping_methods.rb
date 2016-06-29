class AddActiveToStallShippingMethods < ActiveRecord::Migration
  def up
    add_column :stall_shipping_methods, :active, :boolean, default: true

    ShippingMethod.update_all(active: true)
  end

  def down
    remove_column :stall_shipping_methods, :active
  end
end
