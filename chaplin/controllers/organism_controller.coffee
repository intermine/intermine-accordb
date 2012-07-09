define [
    'chaplin'
    'views/organism_view'
], (Chaplin, OrganismView) ->

    class OrganismController extends Chaplin.Controller

        historyURL: (params) -> ''

        index: (params) ->
            @view = new OrganismView()