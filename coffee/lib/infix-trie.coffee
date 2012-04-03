class InfixTrie

  constructor: (is_infix, is_case_sensitive) ->
    @is_infix = !!is_infix;
    @is_case_sensitive = !!is_case_sensitive;
    @root = [null, {}, false] # masterNode: object, char -> trieNode map, traverseToggle
    @cache = {}
    if @is_infix
      @infix_roots = {}
    else
      @infix_roots = null;

  clean_string: (str) ->
    if !@is_case_sensitive
      str = str.toLowerCase()
    str = str.replace(/^\s+|\s+$/g,"")
    # invalid char clean here
    str;

  add: (key, object) ->
    key = this.clean_string(key)
    curr_node = @root

    for i in [0...key.length]
      chr = key.charAt(i)
      node = curr_node[1]
      if chr of node
        curr_node = node[chr]
      else
        curr_node = node[chr] = [null, {}, @root[2]]

        if @is_infix
          if chr of @infix_roots
            @infix_roots[chr].push(curr_node)
          else
            @infix_roots[chr] = [curr_node]

    if curr_node[0]
      curr_node[0].push(object)
    else
      curr_node[0] = [object]

    true

  map_new_array: (node_array, chr) ->
    if node_array.length && node_array[0] is @root
      if @is_infix
        return (@infix_roots[chr] || [])
      else
        prefix_root = @root[1][chr]
        return if prefix_root then [prefix_root] else []

    ret_array = []

    for i in [0...node_array.length]
      this_nodes_array = node_array[i][1]
      if this_nodes_array.hasOwnProperty(chr)
        ret_array.push(this_nodes_array[chr])

    ret_array

  find_node_array: (key) ->
    ret_array = [@root]
    key = @clean_string(key)

    this_cache = @cache

    for i in [0...key.length]
      chr = key.charAt(i)
      if (this_cache.chr is chr)
        ret_array = this_cache.hit
      else
        ret_array = @map_new_array(ret_array, chr);
        this_cache.chr = chr
        this_cache.hit = ret_array
        this_cache.next = {}

      this_cache = this_cache.next

    ret_array

  mark_and_retrieve: (array, trie, toggle_set) ->
    stack = [trie]
    while stack.length > 0
      this_trie = stack.pop()
      if this_trie[2] is toggle_set
        continue

      this_trie[2] = toggle_set
      if this_trie[0]
        array.unshift(this_trie[0])

      for own chr, t of this_trie[1]
        stack.push(t)

    true

  find: (key) ->
    trie_node_array = @find_node_array(key)
    toggle_to = !@root[2]
    matches = []
    misses = []

    for trie in trie_node_array
      this.mark_and_retrieve(matches, trie, toggle_to)

    this.mark_and_retrieve(misses, @root, toggle_to)

    {matches: matches, misses: misses}

this.InfixTrie = InfixTrie
