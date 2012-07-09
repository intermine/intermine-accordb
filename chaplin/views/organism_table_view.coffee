define [
    'chaplin'
    'views/organism_table_view'
    'templates/organism_table'
], (Chaplin) ->

    class OrganismTableView extends Chaplin.View

        container: '.table'

        # Template name on global `JST` object.
        templateName: 'organism_table'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]