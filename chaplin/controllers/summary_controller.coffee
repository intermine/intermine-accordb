define [
    'chaplin'
    'views/summary_view'
], (Chaplin, SummaryView) ->

    class SummaryController extends Chaplin.Controller

        whoAmI: 'SummaryController'

        historyURL: (params) -> ''

        index: (params) ->
            @view = new SummaryView()