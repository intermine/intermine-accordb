define [
    'chaplin'
    'views/upload_results_view'
    'views/upload_datasets_view'
    'templates/upload'
], (Chaplin, UploadResultsView, UploadDataSetsView) ->

    class UploadView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'upload'
        
        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        initialize: ->
            super

            @delegate 'click', 'form.upload a.btn', @uploadHandler

            @

        afterRender: ->
            super

            # Load the datasets mini-view populating the available ones.
            $.get 'api/datasets', (data) ->
                new UploadDataSetsView 'model': new Chaplin.Model data
        
        uploadHandler: (e) ->
            # Hide the btn.
            $(e.target).remove()

            # Show progress bar.
            $(@el).find('.progress').show()

            # Serialize the form.
            values = {}
            for object in $(@el).find('form.upload').serializeArray()
                values[object.name] = object.value

            # POST it.
            $.ajax
                'type':     'POST'
                'url':      'api/upload'
                'dataType': 'json'
                'data':     values
                'success': (data) ->
                    new UploadResultsView 'model': new Chaplin.Model data
                'error': (data) =>
                    $(@el).find('.progress').remove()
                    
                    try
                        msg = JSON.parse(data.responseText).message
                        $(@el).html '<div class="alert alert-warning">Server error: ' + msg + '.</div>'
                    catch e
                        $(@el).html '<div class="alert alert-error">Something went wrong.</div>'