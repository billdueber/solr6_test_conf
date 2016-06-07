# generate_dynamic_fields.rb -- generate all the nasty dynamic fields
# used by this schema setup.
#
# General use: ruby generate_dynamic_fields.rb > dynamic_fields.xml
#
# 


# A mapping of suffixes to field types. The
# leading underscore is implied (i.e., put t:, not
# _t: )

suffix_type_mapping = {
  t:        'text',
  tp:       'text_nostem', # "proper"
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
  
  tf:       [:t, :f],
  tsearch:  [:t, :tl, :tp],
  tsearchf: [:t, :tl, :tp, :f],
  ef:       [:e, :f],
  
}

#### I'd leave this alone until Bill refactors it 


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

    To understand what the heck is going on here (or at least
    what I was going for, see the docs at
    https://github.com/billdueber/solr6_test_conf

    General use: ruby #{__FILE__} > schema/dynamic_fields.xml
    
    Note that just because you're using dynamic fields it
    doesn't mean you can't special-case things in your
    schema.xml. You can have a few fields that you
    specify exactly what the name and type will be,
    and let everything else fall through to the
    dynamic types.
     
    In addition to all the dynamicField/copyField stuff
    (ad nauseum, below), we'll also set up a couple 
    dynamicType definitions for common cases where we want 
    simpler resulting field names
    
    Sort types have to be single valued; we'll use ssort for
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


suffix_type_mapping.each_pair do |bt, type|
  if type.is_a?(Array)
    puts "\n\n<!-- Suffix _#{bt}, mapping to multiple other suffixes: [#{type.join(', ')}] -->"
    puts multi_fset(bt, type)
  else
    puts "\n\n<!-- Suffix _#{bt}, producing indexed fields of type #{type} -->"
    puts normal_fset(bt, type)
  end
  puts "\n"
end

puts(<<-C3)
  <!-- Finally, we define our most base types. Anything that matches *_a will be
  turned into a multivalued stored string, and anything else will be a single-valued
  stored string.
  
  These are mostly used by the copyField directives above, but there's nothing
  stopping you from just sending a bare field name to get a stored, not indexed
  field (e.g., title_display for singular, callnumber_a for multiple call numbers)
  -->
C3
   
puts   %Q[<dynamicField name="*_a" type="string" indexed="false" stored="true" multiValued="true" />]
puts   %Q[<dynamicField name="*"   type="string" indexed="false" stored="true" multiValued="false" />]
 
  
