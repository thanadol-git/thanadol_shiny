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

## Data 
The script download the zip file from my personal ggdrive. In the zip file, it contains three folders; www, Exercise and Upload. www contains mostly pdf file that needs to be used within the app (mainly paper articles). Exercise is where the worksheet is stored. In 2023, we skipped hosting the file in the app but push it on canvas instead. Lastly, Upload is where the data used in the lab is stored. The data may looked a bit different that the origin article as it has been masked. it is also simplified to be loaded efficiently iwthin the app. 

## Contact

This shiny app was built by [@thanadol-git](https://github.com/thanadol-git).

