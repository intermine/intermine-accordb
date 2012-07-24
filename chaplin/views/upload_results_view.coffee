define [
    'chaplin'
    'templates/upload_results'
], (Chaplin) ->

    class UploadResultsView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'upload_results'
        
        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        # Serialize using toJSON.
        getTemplateData: ->
            data = []
            @collection.each (model) -> data.push model.toJSON()
            
            'rows': data