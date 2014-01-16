fs = require 'fs'
wrench = require 'wrench'
cs = require 'coffee-script'
eco = require 'eco'

# Write to file, sync, create dirs if needed.
write = (path, text) ->
    writeFile = (path) ->
        id = fs.openSync path, 'w', 0o0666
        fs.writeSync id, text, null, 'utf8'

    # Create the directory if it does not exist first.
    dir = path.split('/').reverse()[1...].reverse().join('/')
    if dir isnt '.'
        try
            fs.mkdirSync dir, 0o0777
        catch e
            if e.code isnt 'EEXIST' then throw e
        
        writeFile path
    else
        writeFile path

# Compile sources.
for file in wrench.readdirSyncRecursive './chaplin'
    console.log './chaplin/' + file
    
    switch (file.split('.')).pop()
        # Compile source cs classes.
        when 'coffee'
            js = cs.compile fs.readFileSync './chaplin/' + file, 'utf-8'
            write './public/js/' + file[0...-7] + '.js', js
        # Compile eco templates.
        when 'eco'
            js = eco.precompile fs.readFileSync './chaplin/' + file, 'utf-8'
            js = "this.JST || (this.JST = {});\nthis.JST['#{file.split('/').pop()[0...-4]}'] = #{js}"
            write './public/js/' + file[0...-4] + '.js', js