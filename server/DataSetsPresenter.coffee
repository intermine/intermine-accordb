# Get back the homologue datasets we can use.
app.router.path '/api/datasets', ->
    @get ->
        app.log.info "Get homologue datasets"

        @res.writeHead 200, "content-type": "application/json"
        @res.write JSON.stringify
            'dataSets': DB.dataSets
        @res.end()