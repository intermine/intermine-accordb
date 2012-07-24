define [
    'chaplin'
    'templates/upload_results_popover'
], (Chaplin) ->

    class UploadResultsPopoverView extends Chaplin.View

        # Template name on global `JST` object.
        templateName: 'upload_results_popover'
        
        # Clear existing.
        containerMethod: 'append'

        getTemplateFunction: -> JST[@templateName]

        # Custo-fn for 'serializing' data.
        getTemplateData: -> 'model': @model.attributes

        afterRender: ->
            super
            $(@el).css 'position': 'relative'
            @delegate 'click', 'a.close', @remove