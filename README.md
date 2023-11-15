# Shiny app for Lab

This shiny app is for ...

## How to build and run

Install Docker on your computer. Check the [official instruction](https://docs.docker.com/engine/install/).

Clone the repository and navigate to the folder containing the `Dockerfile`. Run the command 
```code
docker build -t shiny-app .
```
Note the dot at the end. This tells docker to search for a `Dockerfile` in the current directory.

To start the container, run 
```code
docker run --rm -p 3838:3838 shiny-app
```
where, 
- `--rm` removes the container if exited or failed
- `-p` specifies ports container-to-host. The shiny app listens on 3838. It is easiest to bind this to the same port.

Now, open a browser and navigate to `localhost:3838`.

## Contact

This shiny app was built by [@thanadol-git](https://github.com/thanadol-git).

