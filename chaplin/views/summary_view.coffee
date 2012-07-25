define [
    'chaplin'
    'views/summary_table_view'
    'templates/summary'
], (Chaplin, SummaryTableView) ->

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
            @model = new Chaplin.Model()
            @model.url = '/api/summary'
            @model.fetch
                'success': (model) ->
                    new SummaryTableView 'model': model