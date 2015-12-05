class AttrAccessorObject

  def self.my_attr_accessor(*names)
    names.each do |name|
      at_name = "@#{name}"
      getter_name = "#{name}=".to_sym

      define_method(name) do
        instance_variable_get(at_name)
      end

      define_method(getter_name) do |value|
        instance_variable_set(at_name, value)
      end
      
    end
  end

end
