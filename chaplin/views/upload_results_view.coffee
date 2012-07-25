define [
    'chaplin'
    'views/upload_results_popover_view'
    'templates/upload_results'
], (Chaplin, UploadResultsPopoverView) ->

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
            [ nOfHomologues, dataSets ] = do =>
                for k, v of @model.attributes.results
                    i = 0
                    for kk, vv of v.homologues
                        j = []
                        for kkk, vvv of vv
                            j.push kkk
                        i++
                    return [ i, j ]

            'query':         @model.attributes.query
            'data':          @model.attributes.results
            # How many homologue organism rows shall we display?
            'nOfHomologues': nOfHomologues
            # How many datasets do we have?
            'dataSets':      dataSets
            # Determine the overlap as the intersection of all homologue dataset gene symbols (not very good...).
            'overlap':       (homologues) ->
                intersection = (a, b) -> value for value in a when value in b
                toList = (obj) -> ( value.symbol for value in obj when value.symbol? )

                res = false
                for dataSet, objects of homologues
                    if !res then res = toList(objects) else res = intersection(res, toList(objects))
                
                res

        # Events.
        afterRender: ->
            super
            @delegate 'click', 'a.matches', @toggleMatches

        toggleMatches: (e) =>
            # Hide any previous.
            @popover?.remove()

            # Parse path.
            path = (target = $(e.target).parent()).attr('data-matches')
            if path
                path = path.split('|')
                matches = @model.get('results')[path[0]]['homologues'][path[1]][path[2]]
                if matches.length
                    @popover = new UploadResultsPopoverView
                        'model': new Chaplin.Model
                            'matches': matches
                            'title': path.join ' '
                    @popover.container = target
                    @popover.render()