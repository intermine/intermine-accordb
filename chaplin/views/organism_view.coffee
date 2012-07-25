define [
    'chaplin'
    'views/organism_table_view'
    'templates/organism'
], (Chaplin, OrganismTableView) ->

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
            @model = new Chaplin.Model()
            @model.url = '/api/organism'
            @model.fetch
                'success': (model) ->
                    new OrganismTableView 'model': model