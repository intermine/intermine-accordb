# AccorDB

Display the overlap between biological datasets among the different model organisms through orthologues.

## Requirements:

You can install all the following dependencies by running:

```bash
npm install -d
```

- [CoffeeScript](http://coffeescript.org/)
- [express](http://expressjs.com/)
- [eco](https://github.com/sstephenson/eco)
- [imjs](https://github.com/alexkalderimis/imjs)
- [socket.io](http://socket.io/)

## Run:

1. Start a node server using `./node_modules/.bin/coffee app.coffee`
2. Visit [http://127.0.0.1:4000/](http://127.0.0.1:4000/)

## Example:

![image](https://raw.github.com/radekstepan/AccorDB/master/example.png)

## Heroku:

For [Heroku](http://heroku.com) deployment, make sure you have an account.

Login to Heroku providing email and password:

```bash
$ heroku login
```

Upload your SSH key:

```bash
$ heroku keys:add ~/.ssh/id_rsa.pub
```

Create the app if does not exist already in your account:

```bash
$ heroku create
```

Deploy your code:

```bash
$ git push heroku master
```

Check the app is running:

```bash
$ heroku ps
```

If not, see the logs:

```bash
$ heroku logs
```

To login to the console:

```bash
$ heroku run bash
```

If you need to rename the app:

```bash
$ git remote rm heroku
$ git remote add heroku git@heroku.com:yourappname.git
```