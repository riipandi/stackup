# Debian LEMP Stack

Debian LEMP Stack installer script.

## Usage

Clone this repo and run `setup.sh`.

```bash
apt -y install git

git clone https://github.com/riipandi/debian-lempstack /usr/src/lempstack ; cd $_

find . -type f -name '*.sh' -exec chmod +x {} \;
find . -type f -name '.git*' -exec rm -fr {} \;

./setup.sh
```

## License

MIT
