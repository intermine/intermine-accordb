# Resolve identifiers and show counts in datasets.
app.router.path '/api/upload', ->
    @post ->
        app.log.info "Resolve gene symbols into homologues"

        if not @req.body?
            app.log.info 'Need to provide form data'.red 

            @res.writeHead 400, "content-type": "application/json"
            @res.write JSON.stringify 'message': 'Need to provide form data'
            @res.end()

        identifiers = (x for x in @req.body['gene-identifiers'].replace(/\,/g, '').replace(/\s{2,}/g, ' ').split(' '))

        app.log.info "Posting identifiers ".grey + new String(identifiers).blue

        request
            'uri':    "#{url}/service/ids"
            'method': "POST"
            'json':
                'identifiers': identifiers
                'type':        'Gene'
        , (err, res, body) =>
            throw err if err

            job = body.uid
            do checkJob = =>
                app.log.info "Checking job #{job}".grey
                request
                    'uri':    "#{url}/service/ids/#{job}/status"
                    'method': "GET"
                , (err, res, body) =>
                    throw err if err

                    body = JSON.parse(body)

                    app.log.info "Job #{job} says #{body.status}".grey

                    switch body.status
                        when 'SUCCESS'
                            app.log.info "Getting result of job #{job}".grey

                            request
                                'uri':    "#{url}/service/ids/#{job}/result"
                                'method': "GET"
                            , (err, res, body) =>
                                throw err if err

                                ids = (key for key, value of JSON.parse(body).results)

                                # Empty results.
                                if not ids.length > 0
                                    app.log.info 'No identifiers resolved'.yellow
                                    @res.writeHead 500
                                    @res.end()
                                else
                                    app.log.info "Getting homologues for genes".grey
                                    
                                    query = clone Queries.homologuesForGenes

                                    # Identifiers received through resolution service.
                                    query.where.push [ "id", "ONE OF", ids ]

                                    # Gene organism constraint.
                                    query.where.push [ "organism.name", "=", @req.body['gene-organism'] ]

                                    # Homologue dataset constraint?
                                    if @req.body['dataset'] isnt '*'
                                        query.where.push [ "homologues.dataSets.name", "=", @req.body['dataset'] ]

                                    # Choose homologue organism.
                                    switch homologueOrganismName = @req.body['homologue-organism']
                                        when '*'
                                            # Exclude paralogs if all other organisms selected.
                                            query.where.push [ "homologues.homologue.organism.name", "ONE OF",
                                                homologueOrganisms = ( x for x in Queries.organisms when x isnt @req.body['gene-organism'] )
                                            ]
                                        else
                                            query.where.push [
                                                "homologues.homologue.organism.name"
                                                "="
                                                homologueOrganismName
                                            ]
                                            homologueOrganisms = [ homologueOrganismName ]

                                    mine.query query, (q) =>
                                        app.log.info q.toXML().blue
                                        q.rows (data) =>
                                            app.log.info "Reorganizing the rows".grey

                                            # This is where we store the resulting collection.
                                            results = {}
                                            # Traverse the gene rows returned.
                                            for row in data
                                                # Identifier is the symbol (preferred) or the internal id.
                                                id = row[1] or row[0]
                                                # Init the skeleton structure.
                                                if not results[id]?
                                                    results[id] =
                                                        'organism': row[2]
                                                        'homologues': {}
                                                    
                                                    # Fill it up with homologue organisms
                                                    for organismName in homologueOrganisms
                                                        results[id]['homologues'][organismName] = {}

                                                    # Fill it up with dataset arrays per homologue organism.
                                                    for org, v of results[id]['homologues']
                                                        if @req.body['dataset'] isnt '*'
                                                            results[id]['homologues'][org][@req.body['dataset']] = []
                                                        else
                                                            for dataSet in DB.dataSets
                                                                results[id]['homologues'][org][dataSet] = []

                                                # Push the homologue object.
                                                results[id]['homologues'][row[5]][row[6]].push
                                                    'primaryIdentifier': row[3]
                                                    'symbol':            row[4]

                                            app.log.info "Returning back the rows".grey

                                            @res.writeHead 200, "content-type": "application/json"
                                            @res.write JSON.stringify
                                                'query':   q.toXML()
                                                'results': results
                                                'meta':
                                                    'homologues': homologueOrganisms
                                                    'dataSets': if @req.body['dataset'] is '*' then DB.dataSets else [ @req.body['dataset'] ]
                                            @res.end()
                        
                        when 'ERROR'
                            app.log.info body.message.red
                            @res.writeHead 500
                            @res.end()
                        when null
                            app.log.info body.error.red
                            @res.writeHead 500
                            @res.end()

                        else setTimeout checkJob, 1000