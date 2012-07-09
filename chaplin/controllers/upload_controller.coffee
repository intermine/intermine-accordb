define [
    'chaplin'
    'views/upload_view'
], (Chaplin, UploadView) ->

    class UploadController extends Chaplin.Controller

        whoAmI: 'UploadController'

        historyURL: (params) -> ''

        index: (params) ->
            @view = new UploadView()