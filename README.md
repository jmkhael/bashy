# bashy

Checkout this into your home:
e.g. /home/jmkhael/workspace

```
pushd ${HOME}
git clone https://github.com/jmkhael/bashy
```

then execute:

```shell
mv ${HOME}/.bashrc ${HOME}/.bashrc.old
ln -s ${HOME}/workspace/bashy/.bashrc ${HOME}/.bashrc
ln -s ${HOME}/workspace/bashy/.bash_ps1 ${HOME}/.bash_ps1
ln -s ${HOME}/workspace/bashy/.bash_profile ${HOME}/.bash_profile
```
