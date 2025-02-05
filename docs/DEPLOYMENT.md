# Deployment

## Production deployment

This can be done on GitHub with the [Deploy to Production](https://github.com/mbta/dotcom/actions/workflows/deploy-prod.yml) workflow. 

Monitor the deploy in AWS Elastic Beanstalk:

- [Health Dashboard](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/health?applicationName=dotcom&environmentId=e-63b6ycpxu2)
- [Events](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/environment/events?applicationName=dotcom&environmentId=e-63b6ycpxu2)
- [Application Versions](https://console.aws.amazon.com/elasticbeanstalk/home?region=us-east-1#/application/versions?applicationName=dotcom)

## Building the distribution package locally

When deploying to our servers, the `mbta/actions/build-push-ecr@v1` and `mbta/actions/eb-ecr-dockerrun@v1` actions perform these steps for us. But for testing or development purposes it is possible to build locally as well.

1. (once) Install Docker: https://docs.docker.com/engine/install/
2. Build the Docker image:

   - `docker build -t dotcom .`

This will build the release in a Docker container.

The root (three-stage) `Dockerfile` is responsible for building and running the application:

- Build:
  Because most of us develop on a Mac but the servers are Linux, we need to run the build inside a Docker (Elixir) container so that everything is compiled correctly. The build uses `distillery` to make the Erlang release, along with all our dependencies.
  For the frontend assets, we use a Node container.

- Run:
  The part of the Dockerfile used to run the application (last stage) runs the script that `distillery` provides for us to run the server (`/root/rel/site/bin/site foreground`). At startup, the `relx` application looks for configuration values that look like `${VARIABLE}` and replaces them with the `VARIABLE` environment variable. This allows us to make a single build, but use it for different environments by changing the environment variables.

## Staging deployment

Deploying to our staging servers can also be done through GitHub Actions.

![](run_workflow.png)

Developers can manually request a deploy of any branch by using any of the deploy workflows. The deployment will be held in a "waiting" state until approved by an active developer. Active developers may approve their own requests.
