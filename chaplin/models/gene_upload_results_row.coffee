define [
    'chaplin'
], (Chaplin) ->

    class GeneUploadResultsRow extends Chaplin.Model

        # Determine the overlap as the intersection of all homologue dataset gene primaryIds (not very good...).
        getOverlap: ->
            res = false
            for dataSet, objects of @get('homologue')['dataSets']
                list = _.pluck objects, 'primaryIdentifier'

                if !res then res = list
                else
                    # Make an intersection of two lists.
                    res = ((a, b) -> value for value in a when value in b)(res, list)
            
            # Now turn it into a 'nice' list of symbols first...
            if res.length > 0
                for i in [0...res.length]
                    res[i] = _(objects).filter( (obj) -> obj.primaryIdentifier is res[i] )[0].symbol or res[i]

            res

        initialize: ->
            super
            @set 'overlap', @getOverlap()
            @

        getAttributes: -> @toJSON()