define [
    'chaplin'
    'templates/summary'
], (Chaplin) ->

    class SummaryView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'summary'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]