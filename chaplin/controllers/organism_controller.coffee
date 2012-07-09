define [
    'chaplin'
    'views/organism_view'
], (Chaplin, OrganismView) ->

    class OrganismController extends Chaplin.Controller

        whoAmI: 'OrganismController'

        historyURL: (params) -> ''

        index: (params) ->
            @view = new OrganismView()