define ->
    
    # The routes for the application. This module returns a function.
    # `match` is match method of the Router
    (match) ->

        match '',         'upload#index'
        match 'upload',   'upload#index'
        match 'summary',  'summary#index'
        match 'organism', 'organism#index'