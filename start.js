// Generated by CoffeeScript 1.4.0
(function() {
  var cs, eco, file, fs, js, wrench, write, _i, _len, _ref;

  fs = require('fs');

  wrench = require('wrench');

  cs = require('coffee-script');

  eco = require('eco');

  write = function(path, text) {
    var dir, writeFile;
    writeFile = function(path) {
      var id;
      id = fs.openSync(path, 'w', 0x1b6);
      return fs.writeSync(id, text, null, 'utf8');
    };
    dir = path.split('/').reverse().slice(1).reverse().join('/');
    if (dir !== '.') {
      try {
        fs.mkdirSync(dir, 0x1ff);
      } catch (e) {
        if (e.code !== 'EEXIST') {
          throw e;
        }
      }
      return writeFile(path);
    } else {
      return writeFile(path);
    }
  };

  _ref = wrench.readdirSyncRecursive('./chaplin');
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    file = _ref[_i];
    console.log('./chaplin/' + file);
    switch ((file.split('.')).pop()) {
      case 'coffee':
        js = cs.compile(fs.readFileSync('./chaplin/' + file, 'utf-8'));
        write('./public/js/' + file.slice(0, -7) + '.js', js);
        break;
      case 'eco':
        js = eco.precompile(fs.readFileSync('./chaplin/' + file, 'utf-8'));
        js = "this.JST || (this.JST = {});\nthis.JST['" + (file.split('/').pop().slice(0, -4)) + "'] = " + js;
        write('./public/js/' + file.slice(0, -4) + '.js', js);
    }
  }

  require('./server.coffee');

}).call(this);
