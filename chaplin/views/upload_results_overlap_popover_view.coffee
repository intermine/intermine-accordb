define [
    'chaplin'
    'templates/upload_results_overlap_popover'
], (Chaplin) ->

    class UploadResultsOverlapPopoverView extends Chaplin.View

        # Template name on global `JST` object.
        templateName: 'upload_results_overlap_popover'
        
        # Clear existing.
        containerMethod: 'append'

        getTemplateFunction: -> JST[@templateName]

        # Custo-fn for 'serializing' data.
        getTemplateData: -> 'model': @model.attributes

        afterRender: ->
            super
            $(@el).css 'position': 'relative'
            @delegate 'click', 'a.close', @remove