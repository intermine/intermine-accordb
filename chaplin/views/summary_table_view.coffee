define [
    'chaplin'
    'views/summary_table_view'
    'templates/summary_table'
], (Chaplin) ->

    class SummaryTableView extends Chaplin.View

        container: '.table'

        # Template name on global `JST` object.
        templateName: 'summary_table'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]