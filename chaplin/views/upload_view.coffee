define [
    'chaplin'
    'templates/upload'
], (Chaplin) ->

    class UploadView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'upload'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]