'use strict'

angular.module 'ui.autocomplete'
  .controller 'UIAutocompleteController', (
    UIAutocompleteService
    $element
    $scope
  ) ->

    uiac = @

    uiac.$postLink = ->
      UIAutocompleteService.setupByElement $element, uiac, $scope

    uiac.$onDestroy = ->
      UIAutocompleteService.cleanupByElement $element, uiac

    return