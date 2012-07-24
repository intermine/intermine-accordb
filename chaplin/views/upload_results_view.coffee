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

        # Custo-fn for 'serializing' data.
        getTemplateData: ->
            console.log @model.attributes

            [ nOfHomologues, dataSets ] = do =>
                for k, v of @model.attributes
                    i = 0
                    for kk, vv of v.homologues
                        j = []
                        for kkk, vvv of vv
                            j.push kkk
                        i++
                    return [ i, j ]

            'data':          @model.attributes
            # How many homologue organism rows shall we display?
            'nOfHomologues': nOfHomologues
            # How many datasets do we have?
            'dataSets':      dataSets