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

        # Toggle the matches popover view.
        toggleMatches: (e) =>
            # Hide any previous.
            @popover?.remove()

            matches = @model.get('homologue')['dataSets'][dataSet = (target = $(e.target).parent()).attr('data-matches')]
            
            @popover = new UploadResultsPopoverView
                'model': new Chaplin.Model
                    'model':   @model.getAttributes()
                    'matches': matches
                    'dataSet': dataSet
                    'title':   [ @model.get('gene')['identifier'], 'in', dataSet, 'for', @model.get('homologue')['organism'] ].join(' ')
            @popover.container = target
            @popover.render()