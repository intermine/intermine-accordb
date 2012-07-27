define [
    'chaplin'
], (Chaplin) ->

    class GeneUploadResultsRow extends Chaplin.Model

        getAttributes: ->
            _.extend @toJSON(),
            # Determine the overlap as the intersection of all homologue dataset gene primaryIds (not very good...).
            'overlap': (homologues) ->
                intersection = (a, b) -> value for value in a when value in b
                toList = (obj) -> ( value.primaryIdentifier for value in obj when value.primaryIdentifier? )

                res = false
                for dataSet, objects of homologues
                    if !res then res = toList(objects) else res = intersection(res, toList(objects))
                res