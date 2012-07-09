define [
    'chaplin'
    'templates/organism'
], (Chaplin) ->

    class OrganismView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'organism'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]