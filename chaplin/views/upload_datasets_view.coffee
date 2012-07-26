define [
    'chaplin'
    'templates/upload_datasets'
], (Chaplin) ->

    class UploadDataSetsView extends Chaplin.View

        tagName: 'select'

        # Append to the form select field.
        container: 'form.upload div.dataset'

        # Template name on global `JST` object.
        templateName: 'upload_datasets'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        getTemplateData: -> @model.toJSON()

        # Add the name attribute.
        afterRender: ->
            super

            $(@el).attr 'name': 'dataset'