# To be used instead of require "cfpropertylist". Restores extensions from
# Plist overwritten by CFPropertyList.

require "cfpropertylist"
require "plist"

# Brute-force solution to conflict between #to_plist introduced by
# CFPropertyList and plist. Remove the method added by CFPropertyList
# and restore the method from Plist::Emit. Each class gains a
# #to_binary_plist method equivalent to #to_plist from CFPropertyList.
#
# CFPropertyList also adds Enumerator#to_plist, but there is no such
# method from Plist, so leave it.
[Array, Hash].each do |c|
  if c.method_defined?(:to_plist)
    begin
      c.send(:alias_method, :to_binary_plist, :to_plist)
      c.send(:remove_method, :to_plist)
    rescue NameError
    end
  end
  c.module_eval("include Plist::Emit", __FILE__, __LINE__)
end
