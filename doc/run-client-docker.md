To run the intarocryptocurrency wallet client in a docker container:

- Install docker https://docs.docker.com/install/
- Run :
`docker run -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v <absolute-path-to-intarocryptocurrency-sources>:/project intarocryptocurrency/run_wallet`
