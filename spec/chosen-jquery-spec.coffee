describe "Chosen", ->

  context = {}
  chosen = null
  select = null
  container = null

  beforeEach ->
    container = $('<div/>')
    select = $('<select/>')
    countries.forEach (value) ->
      select.append($('<option/>').val(value).text(value))
    container.append(select)
    context.chosen = chosen = select.chosen().data('chosen')

  sharedBehavior(context)
  
  it "should run fast with large number of options", ->
    
    stats = 
      stats: {}
      countStat: (label, duration) ->
        if @stats[label]
          @stats[label].push(duration);
        else
          @stats[label] = [duration];
      summary: ->
        console.info(JSON.stringify(@stats, null, " "))
    
    applyChosen = (group) ->
      time = Date.now()
      select.chosen({width: '50px'})
      stats.countStat(group+'-Apply', Date.now() - time)

    chosenOpen = (chosen, group) ->
      time = Date.now()
      chosen.results_show()
      stats.countStat(group+'-Open', Date.now() - time)

    chosenSearch = (chosen, group, terms) ->
      time = Date.now()
      chosen.search_field.val(terms)
      chosen.results_search()
      stats.countStat(group+'-Search'+terms, Date.now() - time)

    chosenTest = (group)->
      applyChosen(group)
      chosenOpen(chosen, group);

      chosenSearch(chosen, group, '1');
      chosenSearch(chosen, group, '12');
      chosenSearch(chosen, group, '123');
      chosenSearch(chosen, group, '12');
      chosenSearch(chosen, group, '1');
      chosenSearch(chosen, group, '');

    for value in [0..1000]
      select.append($('<option/>').val(value).text(value))
    select.trigger('chosen:updated')
    
    console.info('Start')
    start = Date.now()
    for i in [0..50]
      chosenTest('single')

    select.attr('multiple', 'multiple')

    for i in [0..50]
      chosenTest('multi')

    stats.summary()
    console.info('End: ' + ( Date.now() - start ))

    