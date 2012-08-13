define [
    'chaplin'
    'md5'
    'templates/upload_results_popover'
], (Chaplin, md5) ->

    class UploadResultsPopoverView extends Chaplin.View

        # Template name on global `JST` object.
        templateName: 'upload_results_popover'
        
        # Clear existing.
        containerMethod: 'append'

        getTemplateFunction: -> JST[@templateName]

        # Custo-fn for 'serializing' data.
        getTemplateData: ->
            'model': @model.attributes
            'color': @color

        afterRender: ->
            super
            $(@el).css 'position': 'relative'
            @delegate 'click', 'a.close', @remove

        # Text to RGB color.
        color: (text) ->
            hash = md5 text
            rgb = [ parseInt(hash[0..1],16), parseInt(hash[1..2],16), parseInt(hash[2..3],16) ].join(',')
            "rgb(#{rgb})"