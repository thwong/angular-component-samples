'use strict'

angular.module 'ui.autocomplete'
  .service 'UIAutocompleteService', (
    WS_API_SERVER_MAPPING
    WS_UI_AUTOCOMPLETE
    WSOriginHelper
    ClientStore
    $translate
    $timeout
  ) ->

    api = @

    ###
    Setup the semantic-ui dropdown widget using the supplied element
    @param {Object} element - The DOM element that contains the dropdown markup
    @param {Object} ctrl - The controller object (passed in from the UIAutocomplete controller)
    @param {Object} scope - The component scope (used for handling scope watch and apply)
    ###
    api.setupByElement = (element, ctrl, scope) ->
      return unless element? and ctrl?
      return unless (angular.isFunction element.find) and (angular.isFunction element.dropdown)
      # Set the basic HTML (i.e., ng-class) before the semantic-ui module is initialized
      _setupHtml ctrl
      # Wait for angular rendering of initial HTML
      $timeout ->
        _dropdown = element.find(WS_UI_AUTOCOMPLETE.CLASS).dropdown _getConfig ctrl, scope
        # Send pre-selected values to Semantic UI Dropdown widget to select
        if ctrl.preSelected?
          _dropdown.dropdown WS_UI_AUTOCOMPLETE.SET_METHOD, ctrl.preSelected
        _setupFlagWatchers _dropdown, ctrl, scope
      return # Explicit return to avoid DOM access warning

    ###
    Get an API setting object for connecting to the backend AutoSuggest API
    @param {Object} namespaces - Backend AutoSuggest API namespaces (should use values from WS_UI_AUTOCOMPLETE constants)
    @param {Object} template - Optional template object for formatting the data (should use values from WS_UI_AUTOCOMPLETE constants)
    ###
    api.getApiSettings = (namespaces, template) ->
      return null unless namespaces?
      api = angular.extend {}, WS_UI_AUTOCOMPLETE.DEFAULT_API_SETTING,
        beforeXHR: _beforeXhrHandler
        beforeSend: _beforeSendHandler
        onResponse: _onResponseHandler.bind template: template
        data: angular.extend {}, WS_UI_AUTOCOMPLETE.DEFAULT_DATA_SETTING, namespaces: namespaces
      api

    ###
    Clean up the semantic-ui dropdown element, events, and watchers
    @param {Object} element - The DOM element that contains the dropdown markup
    @param {Object} ctrl - The controller object (passed in from the UIAutocomplete controller)
    ###
    api.cleanupByElement = (element, ctrl) ->
      # Unbind the clear-flag watcher if existed
      if angular.isFunction ctrl.unbindClearFlagWatcher then ctrl.unbindClearFlagWatcher()
      _dropdown = if angular.isFunction element.find then element.find WS_UI_AUTOCOMPLETE.CLASS else null
      if _dropdown and (angular.isFunction _dropdown.unbind) and (angular.isFunction _dropdown.remove)
        _dropdown.unbind().remove()

    # Private function to format the result
    _getFormattedItem = (suggestion, template) ->
      _data = null
      # Return null if backend data contain invalid JSON
      try _data = angular.fromJson suggestion catch e then return null
      # Use the default template if custom template is not passed in
      template = template ? WS_UI_AUTOCOMPLETE.DEFAULT_TEMPLATE
      name: (template.formatName _data), value: (template.formatValue _data)

    # Private function to define the API response handler
    _onResponseHandler = (resp) ->
      return success: false unless resp.suggestions?
      _items = []
      _template = @template
      # Format each of the result item using the supplied template
      R.forEach (_suggestion) ->
        _item = _getFormattedItem _suggestion, _template
        if _item then _items.push _item
      , resp.suggestions ? []
      success: true, results: _items

    # Private function to handle XHR request
    _beforeXhrHandler = (xhr) ->
      _CFG = WS_UI_AUTOCOMPLETE.API_CONFIG
      _token = ClientStore.wsToken()
      # Add the Bearer token if exists (some API calls such as company selector will work without token)
      if _token? and _token.length then xhr.setRequestHeader _CFG.AUTH_HEADER, "Bearer #{_token}"
      xhr.setRequestHeader _CFG.CONTENT_TYPE_HEADER, _CFG.CONTENT_TYPE_VALUE
      xhr

    # Private function to format the request URL
    _beforeSendHandler = (settings) ->
      # Prepend the remote API address using the API_SERVER_MAPPING (just like how all other Angular ajax calls are handled)
      _apiRoot = WS_API_SERVER_MAPPING[WSOriginHelper.getServerOrigin()]
      if _apiRoot? then settings.url = WSOriginHelper.prependApiRoot _apiRoot, settings.url
      settings.data.prefix = settings.urlData.query
      settings.data = angular.toJson settings.data
      settings

    # Private function to set the HTML before the semantic-ui dropdown module is initialized
    # This is needed since the dropdown module uses the element class name to configure its functionalities (i.e., allowing search)
    _setupHtml = (ctrl) ->
      ctrl.isMultiple = not (ctrl.allowMultiple? and (ctrl.allowMultiple is 'false'))

    # Private function to watch for the clear flag change
    _setupFlagWatchers = (_dropdown, ctrl, scope) ->
      if ctrl.clearFlag?
        ctrl.unbindClearFlagWatcher = scope.$watch WS_UI_AUTOCOMPLETE.CTRL_CLEAR_FLAG, (newVal, oldVal) ->
          if (newVal isnt oldVal) and newVal
            $timeout -> _dropdown.dropdown WS_UI_AUTOCOMPLETE.CLEAR_METHOD

    # Private function to hook up the onUpdate/onAdd/onRemove callback functions
    _setupCallbackFunctions = (_cfg, ctrl, scope) ->
      if angular.isFunction ctrl.onUpdate
        _cfg.onChange = (values) ->
          scope.$apply ->
            # Semantic UI Dropdown module sends selected values as comma separated value
            ctrl.onUpdate values: (if angular.isString values then values.split ',' else [])
      if angular.isFunction ctrl.onAdd
        _cfg.onAdd = (value) ->
          scope.$apply -> ctrl.onAdd value: value
      if angular.isFunction ctrl.onRemove
        _cfg.onRemove = (value) ->
          scope.$apply -> ctrl.onRemove value: value

    # Private function to set up various dropdown widget configuration flags
    _setupConfigurationFlags = (_cfg, ctrl) ->
      if ctrl.api?
        _cfg.apiSettings = ctrl.api
      if ctrl.allowAdditions? and (ctrl.allowAdditions is 'true')
        _cfg.allowAdditions = true
        _cfg.hideAdditions = false
      _cfg.preserveHTML = ctrl.preserveHtml? and (ctrl.preserveHtml is 'true')

    # Private function to set up the default messaging for the widget
    _setupMessages = (_cfg, ctrl) ->
      _cfg.message =
        addResult: $translate.instant 'ui_autocomplete.msg_add_result'
        count: $translate.instant 'ui_autocomplete.msg_count'
        maxSelections: $translate.instant 'ui_autocomplete.msg_max_selections'
        noResults: $translate.instant 'ui_autocomplete.msg_no_results'

    # Private function to the the final configuration object to initialize the dropdown component
    _getConfig = (ctrl, scope) ->
      _cfg = {}
      _setupCallbackFunctions _cfg, ctrl, scope
      _setupMessages _cfg, ctrl
      _setupConfigurationFlags _cfg, ctrl
      _cfg

    api