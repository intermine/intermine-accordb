define [
    'chaplin'
    'views/upload_results_popover_view'
    'templates/upload_results_row'
], (Chaplin, UploadResultsPopoverView) ->

    class UploadResultsRowView extends Chaplin.View

        tagName: 'tr'

        container: 'tbody#rows'

        containerMethod: 'append'

        templateName: 'upload_results_row'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        afterRender: ->
            super
            # Events.
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