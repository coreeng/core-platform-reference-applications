# CECG IDP Reference Application - GoLang

Reference Golang application for the CECG Developer Platform.

# Path to Production

The P2P uses GitHub Actions to interact with the platform.
There are a few variables that you need to set up in order for this to work. On the repositories' web page, navigate to `Settings -> Environments` and ensure you have `gcp-dev` and `gcp-prod` environments created.
For each of these, you'll need these variables:
- `BASE_DOMAIN`: The base domain configured on the deployment, prefixed by the environment (e.g. `gcp-dev.cecg.platform.cecg.io`)
- `INTERNAL_SERVICES_DOMAIN`: The internal services domain configured on the deployment, prefixed by the environment (e.g. `gcp-dev-internal.cecg.platform.cecg.io`)
- `DPLATFORM`: As defined by `environment` attribute in your developer platform config file (e.g. `gcp-dev`)
- `PROJECT_ID`: The GCP Id of the project. You can see this in the GCP console page. (e.g. `core-platform-ab1234de`)
- `PROJECT_NUMBER`: Similar to project id, this is the numeric value for the GCP project. You can see this value in GCP console next to the project id. (e.g. `123456789012`)

In addition, you need to make sure that you have a repository environment variables with:
- `TENANT_NAME`: Name of your tenant. There is a namespace created with the same name as your tenant and that will be used as a parent namespace.
- `FAST_FEEDBACK`=`{"include": [{"deploy_env": "gcp-dev"}]}` - Defines which environment the fast feedback pipeline runs on
- `EXTENDED_TEST`=`{"include": [{"deploy_env": "gcp-dev"}]}` -  Defines which environment the extended tests pipeline runs on
- `PROD`=`{"include": [{"deploy_env": "gcp-prod"}]}` -  Defines which environment the production pipeline runs on

As part of the P2P, using Hierarchical Namespace Controller, child namespaces will be created:
- `<tenant-name>-functional`
- `<tenant-name>-nft`
- `<tenant-name>-extended`

The application is deployed to each of this following the shape:
```
| Build Service | -> | Functional testing | -> | NF testing | -> | Promote image to Extended tests |
```

The tests are executed as helm tests. For that to work, each test phase is packaged in a docker image and pushed to a registry. 
It's then executed after the deployment of the respective environment to ensure the service is working correctly.

## P2P interface

The P2P uses the `Makefile` to deploy and test the application. It expects these tasks to exist:
* `p2p-build` - Builds the service image and pushes it to the registry
* `p2p-functional` - Runs only functional helm tests
* `p2p-nft` - Runs only NFT helm tests
* `p2p-extended-test` - Runs only extended helm tests
* `p2p-promote-to-extended-test` - Promotes the images when running on main branch and both NFT and Functional steps are successful 

You can run `make help-p2p` to list the available p2p functions or `help-all` to see all available functions.

#### Requirements

The interface between the P2P and the application is `Make`.
For everything to work for you locally you need to ensure you have the following tools installed on your machine:
* Make
* Docker
* Kubectl
* Helm

#### Prerequisites for local run

* GCloud login - `gcloud auth login` 
* GCloud registry login, e.g. `gcloud auth configure-docker europe-west2-docker.pkg.dev`

#### Image Versioning

The version is automatically generated when running the pipeline in GitHub Actions, but when you build the image 
locally using `p2p-build` you may need to specify `VERSION` when running `make` command. 

```
make VERSION=1.0.0 p2p-build
```

#### Building on arm64 

If you are on `arm64` you may find that your Docker image is not starting on the target host. This may be because of 
the incompatible target platform architecture. You may explicitly require that the image is built for `linux/amd64` platform:

```
DOCKER_DEFAULT_PLATFORM="linux/amd64" make p2p-build
```

#### Push the image

There's a shared tenant registry created `europe-west2-docker.pkg.dev/<project_id>/tenant`. You'll need to set your project_id and export this string as an environment variable called `REGISTRY`, for example:
```
export REGISTRY=europe-west2-docker.pkg.dev/MY_PROJECT_ID/tenant
```

#### Ingress URL construction

For ingress to be configured correctly you'll need to set up the environment that you want to deploy to, as well as the base url to be used. 
This must match one of the `ingress_domains` configured for that environment. For example, inside CECG we have an environment called `gcp-dev` that's ingress domain is set to `gcp-dev.cecg.platform.cecg.io`.

This reference app assumes `<environment>.<domain>`, check with your deployment of the CECG developer platform if this is the case.

This will construct the base URL as `<environment>.<domain>`, for example, `gcp-dev.cecg.platform.cecg.io`.

```
export BASE_DOMAIN=gcp-dev.cecg.platform.cecg.io 
```

#### Logs

You may find the results of the test runs in Grafana. The pipeline generates a link with the specific time range. 

To generate a correct link to Grafana you need to make sure you have `INTERNAL_SERVICES_DOMAIN` set up.

```
export INTERNAL_SERVICES_DOMAIN=gcp-dev-internal.cecg.platform.cecg.io 
```

## Functional Testing

Stubbed Functional Tests using [Cucumber Godog](https://github.com/cucumber/godog)

This namespace is used to test the functionality of the app. Currently, using BDD (Behaviour driven development)

## NFT

This namespace is used to test how the service behaves under load, e.g. 1_000 TPS, P99 latency < 500 ms for 3 minutes run.

There are 2 endpoints available for testing:
- `/hello` - simply returns `Hello world`.
- `/downstream/path` - makes an HTTP call to another dependent service (downstream) and forwards the response.

#### Load Generation

We are using [K6](https://k6.io/) to generate constant load, collect metrics and validate them against thresholds.

There are 2 test examples: `hello.js` and `downstream.js`.

`helm test` runs K6 scenario in a single Pod.

#### Dependent Service (downstream)

We are priming the dependencies with [WireMock](https://wiremock.org/).
You can register stub responses either by creating static files or dynamically via Admin API.

There is `setup()` function in `downstream.js` that shows how to create stubbed API responses dynamically.

#### Platform Ingress

We can send the traffic to the reference app either via ingress endpoint or directly via service endpoint.

There is `nft.endpoint` parameter in `values.yaml` that can be set to `ingress` or `service`.

## Extended test

This is similar to NFT, but generates much higher load and runs longer, e.g. 10_000 TPS, P99 latency < 500 ms for 10 minutes run.

By default, the extended test is disabled. In order to enable it, you need to explicitly override the variable

```
make RUN_EXTENDED_TEST=true p2p-extended-test
```

or change `RUN_EXTENDED_TEST` to `true` in `Makefile`.

#### Load Generation

We are using [K6](https://k6.io/) to generate the load.
We are using [K6 Operator](https://github.com/grafana/k6-operator) to run multiple jobs in parallel, so that we can reach high
TPS requirements.

We are using the same `downstream.js` as for NFT, but with different parameters.

When running parallel jobs with K6 Operator we are not getting back the aggregated metrics at the end of the test.
We are collecting the metrics with Prometheus and validating the results with `promtool`.

#### Dependent Service (downstream)

We are using [WireMock](https://wiremock.org/). See NFT section for more details.

In general, WireMock has a very good performance, but you can reach its limits when running only 1 replica.
You may need to run several replicas of WireMock to serve more requests. Be aware that dynamic stub definitions are
stored in memory, so you need to register the stubs in each WireMock instance explicitly.

We are deploying WireMock as a StatefulSet, so that we can set up each replica for our tests.

#### Platform Ingress

We can send the traffic to the reference app either via ingress endpoint or directly via service endpoint.
See NFT section for more details.

## Platform Features

> Due to the restrictions applied to your platform you may not be able to enable some of the features

### Monitoring

This feature is needed to allow metrics collection by Prometheus. It needs the metric store (prometheus) to be installed on the parent namespace e.g. `TENANT_NAME`.

By default, Monitoring is disabled. In order to enable it, you need to explicitly override the variable

```
make MONITORING=true p2p-nft
```

or change `MONITORING` to `true` in `Makefile`.

### Dashboarding

This feature allows you to automatically import dashboard definitions to Grafana.

> You may import the dashboard manually by uploading the json definition via browser

By default, `DASHBOARDING` is disabled. In order to enable it, you need to explicitly override the variable

```
make DASHBOARDING=true p2p-nft
```

or change `DASHBOARDING` to `true` in `Makefile`.

The reference app comes with `10k TPS Reference App` dashboard that shows the TPS and latency 
for the load generator, ingress, API server and its downstream dependency. 

This feature depends on metrics collected by `Service Monitor`. 

### K6 Operator

> K6 Operator must be present in the platform in order to run the extended test

You may install it with
```
make deploy-k6-operator
```

## Limiting the CPU usage

When running load tests it is important that we define CPU resource limits. This will allow us to have stable results between runs. 

If we don't apply the limits then the performance of the Pods will depend on the CPU utilization of the node that is running the container.
