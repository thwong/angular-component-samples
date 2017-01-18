'use strict'

angular.module 'ui.person'
  .controller 'PersonViewCtrl', () ->

    pv = @

    # Set the appropriate image class for person.
    _setupDisplay = ->
      pv.imageClass = {}
      if pv.size?
        pv.imageClass[pv.size] = true
      if pv.person.avatar? and pv.person.avatar isnt ''
        pv.imageClass['has-image'] = true

    pv.$onInit = ->
      return unless pv.person?
      _setupDisplay()

    return