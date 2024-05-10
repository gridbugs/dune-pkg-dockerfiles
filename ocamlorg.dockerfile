FROM ubuntu
RUN apt-get update && apt-get install -y opam git curl

# Make a user so we can stop running as root
RUN useradd --create-home user
USER user
WORKDIR /home/user

# Install ocaml and dune
RUN opam init --disable-sandboxing --auto-setup
RUN opam install -y ocaml.4.14.2
# TODO install dune with opam next dune release
ENV DUNE_REVISION=bf465d32b9b63d24c049c1b6844461e26cd33435
RUN opam pin add -y dune "git+https://github.com/ocaml/dune#$DUNE_REVISION"

# Clone ocaml.org
RUN git clone https://github.com/ocaml/ocaml.org
WORKDIR ocaml.org
COPY ocamlorg.diff ocamlorg.diff
RUN patch -p1 < ocamlorg.diff # replaces ocaml dep with ocaml-system and pins some packages

# Install depexts needed by ocaml.org
USER root
RUN apt-get install -y pkg-config libgmp-dev libffi-dev libev-dev openssl libssl-dev zlib1g-dev libcurl4-gnutls-dev libonig-dev autoconf
USER user

# Build ocaml.org
RUN opam exec dune pkg lock
RUN opam exec make

# The default command runs the server
CMD opam exec make start
