define [
    'chaplin'
    'models/gene_upload_results_row'
    'views/upload_results_row_view'
    'templates/upload_results'
], (Chaplin, GeneUploadResultsRow, UploadResultsRowView) ->

    class UploadResultsView extends Chaplin.View

        container: '#app'

        # Template name on global `JST` object.
        templateName: 'upload_results'
        
        # Clear existing.
        containerMethod: 'html'

        # Automatically render after initialization
        autoRender: true

        getTemplateFunction: -> JST[@templateName]

        afterRender: ->
            super

            # Render the individual rows.
            for gene, g of @model.get 'results'
                for homologue, h of g.homologues
                    model = new GeneUploadResultsRow
                        'gene':
                            'identifier': gene
                            'organism':   g.organism
                        'homologue':
                            'organism':   homologue
                            'dataSets':   h
                        'meta':           @model.get('meta')

                    new UploadResultsRowView 'model': model