# AccorDB

Display the overlap between biological datasets among the different model organisms through orthologues.

## Requirements:

You can install all the following dependencies by running:

```bash
npm install -d
```

- [CoffeeScript](http://coffeescript.org/)
- [flatiron](http://flatironjs.org/)
- [eco](https://github.com/sstephenson/eco)
- [imjs](https://github.com/alexkalderimis/imjs)

## Run:

Start the node server using:
```bash
$ foreman start
```

Visit [http://127.0.0.1:5000/](http://127.0.0.1:5000/) or whichever port we started on as specified in `process.env.PORT`

## Example:

![image](https://raw.github.com/radekstepan/AccorDB/master/example.png)

## Redhat OpenShift:

Create an account at [http://openshift.redhat.com](http://openshift.redhat.com) specifying a Node.js 0.6 "Web Cartridge" specifying the url for the app.

Install the OpenShift [client tools](https://openshift.redhat.com/app/getting_started).

Add your public key from `~/.ssh/id_rsa.pub` to your account. You can use xclip to copy the key to the clipboard:

```bash
$ xclip -sel clip < ~/.ssh/id_rsa.pub
```

Add the remote repository, like:

```bash
$ git remote add openshift ssh://a9428e3cb0f2b8e12d0d9935d03bad84@accordb-intermine.rhcloud.com/~/git/accordb.git/
```

Push your changes:

```bash
$ git push -u openshift master
```

In case of trouble, use the OpenShift client tools to debug:

```bash
$ /var/lib/gems/1.8/bin/rhc domain status
```

You can also SFTP into your instance on port `22` [sftp://accordb-intermine.rhcloud.com](sftp://accordb-intermine.rhcloud.com).