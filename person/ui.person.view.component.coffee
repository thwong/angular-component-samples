'use strict'

angular.module 'ui.person'
  .component 'uiPersonView',
    templateUrl: 'app/components/ui/person/ui.person.view.html'
    bindings:
      person: '<'
      size: '@'
      display: '&'
    controller: 'PersonViewCtrl'
    controllerAs: 'pv'