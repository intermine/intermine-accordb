define [
    'chaplin'
    'models/summary'
    'views/summary_table_view'
    'templates/summary'
], (Chaplin, Summary, SummaryTableView) ->

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
                    new SummaryTableView 'model': model