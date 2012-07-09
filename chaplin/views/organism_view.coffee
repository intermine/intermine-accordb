define [
    'chaplin'
    'models/organism'
    'templates/organism'
], (Chaplin, Organism) ->

    class OrganismView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'organism'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        initialize: ->
            super
            @renderData()

        renderData: ->
            @model = new Organism()
            @model.fetch
                'success': (model) ->
                    console.log model