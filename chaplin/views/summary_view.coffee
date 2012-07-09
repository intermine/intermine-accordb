define [
    'chaplin'
    'models/summary'
    'templates/summary'
], (Chaplin, Summary) ->

    class SummaryView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'summary'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        initialize: ->
            super
            @renderData()

        renderData: ->
            @model = new Summary()
            @model.fetch
                'success': (model) ->
                    console.log model