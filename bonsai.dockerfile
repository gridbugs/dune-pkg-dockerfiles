FROM ubuntu
RUN apt-get update && apt-get install -y opam git curl

# Make a user so we can stop running as root
RUN useradd --create-home user
USER user
WORKDIR /home/user

# Install ocaml and dune
RUN opam init --disable-sandboxing --auto-setup
RUN opam install -y ocaml.5.1.1
# TODO install dune with opam next dune release
ENV DUNE_REVISION=bf465d32b9b63d24c049c1b6844461e26cd33435
RUN opam pin add -y dune "git+https://github.com/ocaml/dune#$DUNE_REVISION"

# Clone bonsai
RUN git clone https://github.com/janestreet/bonsai
WORKDIR bonsai
RUN git checkout v0.16
COPY bonsai.diff bonsai.diff
RUN patch -p1 < bonsai.diff # replaces ocaml dep with ocaml-system

# Install depexts needed by bonsai
USER root
RUN apt-get install -y pkg-config libgmp-dev libffi-dev openssl libssl-dev zlib1g-dev
user user

# Generate lockdir and build hello_world example (including dependencies)
RUN opam exec dune pkg lock
RUN opam exec dune build @examples/hello_world/all examples/hello_world/main.bc.js

# The default command is to run a web server serving the hello world example
CMD python3 -m http.server -d _build/default/examples/hello_world/ 8080
