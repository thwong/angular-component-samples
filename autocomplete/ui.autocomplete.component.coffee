'use strict'

angular.module 'ui.autocomplete'
.component 'uiAutocomplete',
  bindings:
    items: '<?'
    api: '<?'
    preSelected: '<?'
    onUpdate: '&?'
    onAdd: '&?'
    onRemove: '&?'
    errorFlag: '<?'
    clearFlag: '<?'
    placeholder: '@?'
    allowMultiple: '@?'
    allowAdditions: '@?'
    preserveHtml: '@?'
  transclude: true
  templateUrl: 'app/components/ui/autocomplete/ui.autocomplete.html'
  controller: 'UIAutocompleteController'
  controllerAs: 'uiac'