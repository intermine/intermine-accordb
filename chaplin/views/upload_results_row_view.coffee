define [
    'chaplin'
    'views/upload_results_popover_view'
    'views/upload_results_overlap_popover_view'
    'templates/upload_results_row'
], (Chaplin, UploadResultsPopoverView, UploadResultsOverlapPopoverView) ->

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
            @delegate 'click', 'a.overlap', @toggleOverlap

        # Toggle the matches popover view.
        toggleMatches: (e) =>
            # Hide any previous.
            @matchesPopover?.remove()

            matches = @model.get('homologue')['dataSets'][dataSet = (target = $(e.target).parent()).attr('data-matches')]
            
            @matchesPopover = new UploadResultsPopoverView
                'model': new Chaplin.Model
                    'model':   @model.getAttributes()
                    'matches': matches
                    'dataSet': dataSet
                    'title':   [ @model.get('gene')['identifier'], 'in', dataSet, 'for', @model.get('homologue')['organism'] ].join(' ')
            @matchesPopover.container = target
            @matchesPopover.render()

        # Toggle the overlap across all datasets popover view.
        toggleOverlap: (e) =>
            # Hide any previous.
            @overlapPopover?.remove()

            @overlapPopover = new UploadResultsOverlapPopoverView 'model': @model
            @overlapPopover.container = $(e.target).parent()
            @overlapPopover.render()
