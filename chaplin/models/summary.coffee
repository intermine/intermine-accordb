define [
    'chaplin'
], (Chaplin) ->

    class Summary extends Chaplin.Model

        url: -> '/api/summary'