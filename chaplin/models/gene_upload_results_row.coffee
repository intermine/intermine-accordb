define [
    'chaplin'
], (Chaplin) ->

    class GeneUploadResultsRow extends Chaplin.Model

        # Determine the overlap as the intersection of all homologue dataset gene primaryIds (not very good...).
        getOverlap: ->
            res = false
            for dataSet, objects of @get('homologue')['dataSets']
                list = _.pluck(objects, 'primaryIdentifier')
                list.push 'fake' # A fake identifier present in 'all'.

                if !res then res = list
                else
                    # Make an intersection of two lists.
                    res = ((a, b) -> value for value in a when value in b)(res, list)
            
            res

        initialize: ->
            super
            @set 'overlap', @getOverlap()
            @

        getAttributes: -> @toJSON()