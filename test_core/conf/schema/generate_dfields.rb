base_types = {
  t:        'text',
  tp:       'text_nostem',
  tl:       'text_leftjustified',
  e:        'exactish',
  i:        'int',
  float:    'float',
  double:   'double',
  str:      'string',
  f:        'string',
  long:     'long',
  dt:       'date',
  isbn:     'isbn',
  lccn:     'lccn',
  num:      'numericID',
  pp:       'pipe_delimited',
  bin:      'binary',
  bool:     'boolean',
  loc:      'location_rpt',
  pt:       'point',
  
  
  tbig:     [:t, :tp],
  tf:       [:t, :f],
  tsearch:  [:t, :tl, :tp],
  tsearchf: [:t, :tl, :tp, :f],
  ef:       [:e, :f],
  
}


def dfield(fname, type, indexed, multiple, stored=false)
  i = indexed ? 'true' : 'false'
  m = multiple ? 'true' : 'false'
  s = stored ? 'true' : 'false'
  %Q[<dynamicField name="*_#{fname}" type="#{type}" indexed="#{i}" stored="#{s}" multiValued="#{m}" />]
end

def basetype_multi(bt, type)
  dfield(bt, type, true, true)
end

def ignored_stored_multi(bt)
  dfield("#{bt}_stored", 'ignored', false, true)
end

def ignored_stored_single(bt)
  dfield("#{bt}_stored_single", 'ignored', false, false)
end

def ignored_single(bt)
  dfield("#{bt}_single", 'ignored', false, false)
end

def ignored_multi(bt)
  dfield(bt, 'ignored', false, true)
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
  rv << ignored_stored_multi(bt)
  rv << ignored_single(bt)
  rv << ignored_stored_single(bt)
  rv << stored_copyfields(bt)
  rv << unstored_copyfields(bt)
  rv
end

# A multi-valued type means we need to copy stuff to 
# more than one endpoint

def multi_fset(bt, suffixes)
  bt = bt.to_s
  rv = []
  
  # Unstored versions
  rv << ignored_multi(bt)
  rv << ignored_single(bt)

  # Copy to the base suffixes
  suffixes.each do |suffix|
    rv << copyfield(bt, suffix)
    rv << copyfield("#{bt}_single", suffix)
  end
  
  # Stored versionss
  storedname  = "#{bt}_stored"
  singlename = "#{bt}_stored_single"    
  multiname  = "#{bt}_stored"

  rv << ignored_stored_single(bt)
  rv << ignored_stored_multi(bt)

  suffixes.each do |suffix|
    rv << copyfield(singlename, suffix)
    rv << copyfield(multiname, suffix)
  end
  rv << storedMulti_copyfield(multiname)
  rv << storedSingle_copyfield(singlename)
end
    


def storedMulti_copyfield(fname)
  %Q[<copyField source="*_#{fname}" dest="*_a" />]
end

def storedSingle_copyfield(fname)
  %Q[<copyField source="*_#{fname}" dest="*" />]
end



def copyfield(fname, bt)
  %Q[<copyField source="*_#{fname}" dest="*_#{bt}" />]  
end

puts "<!-- This file generated from #{File.expand_path $0}
     
    In addition to all the dynamicField/copyField stuff, we'll
    also set up a couple easy dynamicType definitions for
    common cases where we want simpler resulting field names -->"
    
puts "<!-- Sort types have to be single valued; we'll use ssort for
      string sort and isort for integer sort. In both cases,
      if you specify a stored value, it'll show up as a string
      named <fieldname>_sort --> "
      
puts dfield('ssort',        'string',  true, false)
puts dfield('isort',        'long',    true, false)
puts dfield('ssort_stored', 'ignored', false, false)
puts dfield('isort_stored', 'ignored', false, false)
puts %Q[<copyField source="*_ssort_stored" dest="*_sort" />]
puts %Q[<copyField source="*_ssort_stored" dest="*_ssort" />]
puts %Q[<copyField source="*_isort_stored" dest="*_sort" />]
puts %Q[<copyField source="*_isort_stored" dest="*_isort" />]



base_types.each_pair do |bt, type|
  if type.is_a?(Array)
    puts multi_fset(bt, type)
  else
    puts normal_fset(bt, type)
  end
  puts "\n"
end
puts   %Q[<dynamicField name="*_a" type="string" indexed="false" stored="true" multiValued="true" />]
puts   %Q[<dynamicField name="*"   type="string" indexed="false" stored="true" multiValued="false" />]
 
  
