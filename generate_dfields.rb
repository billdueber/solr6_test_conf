base_types = {
  t: 'text',
  tp: 'text_nostem',
  tl: 'text_leftjustified',
  e:  'exactish',
  i:  'int',
  float:  'float',
  double: 'double',
  str: 'string',
  f:   'string',
  long: 'long',
  date: 'date',
  isbn: 'isbn',
  lccn: 'lccn',
  num:  'numericID',
  pp:   'pipe_delimited',
  tf:   [:t, :str],
  tsearch: [:t, :tl, :tp],
  tsearchf: [:t, :tl, :tp, :f],
  ef: [:e, :f],
  
}


def dfield(fname, type, indexed, multiple)
  i = indexed ? 'true' : 'false'
  m = multiple ? 'true' : 'false'
  %Q[<dynamicField name="*_#{fname}" type="#{type}" indexed="#{i}" stored="false" multiValued="#{m}" />]
end

def basetype_multi(bt, type)
  dfield(bt, type, true, true)
end

def ignored_multi(bt)
  dfield("#{bt}_stored", 'ignored', false, true)
end

def ignored_stored_single(bt)
  dfield("#{bt}_stored_single", 'ignored', false, false)
end

def ignored_single(bt)
  dfield("#{bt}_single", 'ignored', false, false)
end


def stored_copyfields(bt)
  multiname = "#{bt}_stored"
  singlename = "#{bt}_stored_single"
  [
    copyfield(multiname, bt),
    storedMulti_copyfield(multiname),
    copyfield(singlename, bt),
    storedSingle_copyfield(singlename)
  ]
end

def unstored_copyfields(bt)
  singlename = "#{bt}_single"
  [ 
    copyfield(singlename, bt)
  ]
end

def normal_fset(bt, type)
  bt = bt.to_s
  rv = []
  rv << basetype_multi(bt, type)
  rv << ignored_multi(bt)
  rv << ignored_single(bt)
  rv << ignored_stored_single(bt)
  rv << stored_copyfields(bt)
  rv << unstored_copyfields(bt)
  rv
end
  
  
# def fset(bt, type)
#   bt = bt.to_s
#   rv = []
#   rv << basetype_multi(bt, type)
#   rv +=
#
#   rv << dfield(bt, type, true, true)
#   fname = "#{bt}_stored"
#   rv << dfield(fname, 'ignored', false, true)
#   rv << copyfield(fname, bt)
#   rv << storedMulti(fname)
#
#   fname = "#{bt}_stored_single"
#   rv << dfield(fname, 'ignored', false, false)
#   rv << copyfield(fname, bt)
#   rv << storedSingle(fname)
#
#   fname = "#{bt}_single"
#   rv << dfield(fname, 'ignored', false, false)
#   rv << copyfield(fname, bt)
#
#
#   rv
# end

def storedMulti_copyfield(fname)
  %Q[<copyField source="*_#{fname}" dest="*_a" />]
end

def storedSingle_copyfield(fname)
  %Q[<copyField source="*_#{fname}" dest="*" />]
end



def copyfield(fname, bt)
  %Q[<copyField source="*_#{fname}" dest="*_#{bt}" />]  
end

puts "<!-- This file generated from #{File.expand_path $0} -->"
base_types.each_pair do |bt, type|
  next if type.is_a?(Array)
  puts normal_fset(bt, type)
  puts "\n"
end
puts   %Q[<dynamicField name="*_a" type="string" indexed="false" stored="true" multiValued="true" />]
puts   %Q[<dynamicField name="*"   type="string" indexed="false" stored="true" multiValued="false" />]
 
  
