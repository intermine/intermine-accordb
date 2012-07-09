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

        initialize: ->
            super

            @delegate 'click', '.upload', @uploadHandler

            @
        
        uploadHandler: ->
            form = $(@el).find('.form')

            $.post '/api/upload',
                'organism':    form.find('.organism').val()
                'identifiers': form.find('.identifiers').val()
            , ((data) ->
                console.log data
            ), "json"