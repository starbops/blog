all

# MD002 - First header should be a top level header
rule 'MD002', :level => 2
# MD004 - Unordered list style
rule 'MD004', :style => :dash
# MD007 - Unordered list indentation
rule 'MD007', :indent => 3
# MD013 - Line length
rule 'MD013', :code_blocks => false, :tables => false
# MD024 - Multiple headers with the same content
rule 'MD024', :allow_different_nesting => true
# MD029 - Ordered list item prefix
rule 'MD029', :style => :one
# MD030 - Spaces after list markers
rule 'MD030', :ul_single => 2, :ol_single => 1, :ul_multi => 2, :ol_multi => 1

# MD025 - Multiple top level headers in the same document
exclude_rule 'MD025'
# MD028 - Blank line inside blockquote
exclude_rule 'MD028'
# MD041 - First line in file should be a top level header
exclude_rule 'MD041'
