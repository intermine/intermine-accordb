define [
    'chaplin'
], (Chaplin) ->

    class Organism extends Chaplin.Model

        url: -> '/api/organism'