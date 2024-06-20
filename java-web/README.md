# Reference Application - Java

## Path to Production (P2P) Interface

The P2P interface is how the generated pipelines interact with the repo.
For the CECG reference this follows the [3 musketeers pattern](https://3musketeers.io/) of using:

* Make
* Docker
* Compose

These all need to be installed.

## Path to Production (P2P) Tooling

### GitHub Actions

ci.yaml in [.github/workflows](.github/workflows) shows how GitHub actions can execute
This same GitHub action can be used for many repos using different technologies as long as the same Make targets are defined.


## Structure

### Service

Service source code, using Java with Sprint Boot.

### Functional

Stubbed Functional Tests using [Cucumber JVM](https://cucumber.io/docs/installation/java/)

### NFT

Load tests using [K6](https://k6.io/).

## Running the application locally

### Application

```
make run-local
```

This application is exposed locally on port 8080 as well as being available to the tests when run with make.
This is as they are in the same docker network.

### Functional Tests

```
make stubbed-functional
```

You should see:

```
io.cecg.reference.Tests.hello world returns ok PASSED
```

### Non-Functional Tests

```
make stubbed-nft
```

You should see:

```
     checks.........................: 100.00% ✓ 6581      ✗ 0
     data_received..................: 829 kB  14 kB/s
     data_sent......................: 546 kB  9.0 kB/s
     http_req_blocked...............: avg=156.98µs min=6.95µs   med=35.04µs  max=23.34ms p(90)=117.7µs  p(95)=356.83µs
     http_req_connecting............: avg=47.77µs  min=0s       med=0s       max=14.68ms p(90)=0s       p(95)=0s
     http_req_duration..............: avg=3.54ms   min=205.7µs  med=2.5ms    max=41.28ms p(90)=7.7ms    p(95)=10.01ms
       { expected_response:true }...: avg=3.54ms   min=205.7µs  med=2.5ms    max=41.28ms p(90)=7.7ms    p(95)=10.01ms
     http_req_failed................: 0.00%   ✓ 0         ✗ 6581
     http_req_receiving.............: avg=501.79µs min=49.87µs  med=275.91µs max=24.07ms p(90)=911.58µs p(95)=1.51ms
     http_req_sending...............: avg=561.45µs min=25.83µs  med=168.25µs max=27.79ms p(90)=1.37ms   p(95)=2.51ms
     http_req_tls_handshaking.......: avg=0s       min=0s       med=0s       max=0s      p(90)=0s       p(95)=0s
     http_req_waiting...............: avg=2.48ms   min=103.75µs med=1.49ms   max=39.93ms p(90)=5.65ms   p(95)=7.85ms
     http_reqs......................: 6581    107.83203/s
     iteration_duration.............: avg=1s       min=1s       med=1s       max=1.04s   p(90)=1.01s    p(95)=1.01s
     iterations.....................: 6581    107.83203/s
     vus............................: 14      min=9       max=200
     vus_max........................: 200     min=200     max=200
```

## How to run the service in minikube

### Install Prerequisites

* A minikube cluster i.e. you've run `minikube start --insecure-registry=minikube:5000`
  * You need to enable the ingress addon by executing: `minikube addons enable ingress` and then follow the instructions from the output e.g. if on mac run `minikube tunnel`
* Kubectl or use `minikube kubectl`

### Registries

You'll need a registry. For the purposes of the local development, we will be using a local registry. The Makefile
`registry` and  `image_name` variables should be updated with your newly created registry details.

### Set up a local registry

How to set up a local registry on minikube:

* Enable the registry addon by executing: `minikube addons enable registry`
* The registry will be exposed on port 5000
* As the registry operates over an insecure connection, the Docker flag `--insecure-registry` will need to be set, so you need to run: `minikube start --insecure-registry minikube:5000`

For Mac users: please follow the instruction here: https://minikube.sigs.k8s.io/docs/handbook/registry/#docker-on-macos .
You will need to redirect port 5000 on the docker virtual machine over to port 5000 on the minikube machine.
Then you will be able to access your local registry on `localhost:5000`.

#### Push the image

Prerequisites:

- The `registry` in the [Makefile](Makefile) should be updated with your newly created registry.

```
make docker-build
make docker-push
```

### Deploy the service

Prerequisites:

- if your local registry is not on `minikube:5000` you will need to update the [deployment yml](service/k8s-manifests/deployment-minikube.yml)
  to pull the image from your local repository. e.g: `localhost:5000` if you are using docker machine on Mac and you followed the registry setup steps from above.

Create the namespace, secrets and the deployments:

```
kubectl apply -f service/k8s-manifests/namespace.yml
kubectl apply -f service/k8s-manifests/pv-dbdata.yml
kubectl apply -f service/k8s-manifests/pvc-dbdata.yml
kubectl apply -f service/k8s-manifests/secret-db.yml
kubectl apply -f service/k8s-manifests/deployment-minikube.yml
```

Deploy the ingress and service:

```
kubectl apply -f service/k8s-manifests/expose.yml
```

Check that the service is running:

```
kubectl get pods -n reference-service-showcase
NAME                                 READY   STATUS    RESTARTS   AGE
reference-service-7cff68d485-q8mw5   1/1     Running   0          142m
```

Check that the ingress is created:

```
kubectl get ingress -n reference-service-showcase
NAME                CLASS   HOSTS   ADDRESS        PORTS   AGE
reference-service   nginx   *       192.168.49.2   80      144m
```

If on Linux you can now access the service on the IP address (which is the minikube IP).

```
curl localhost/service/hello
Hello World!%
```

If this doesn't work ensure you followed the instructions when enabling the minikube ingress addon.

### Run the functional tests against deployed application

This shows how you can run the same tests locally and on a deployed version using the `SERVICE_ENDPOINT` environment variable.

E.g: For a local run:

```
SERVICE_ENDPOINT="http://localhost:8080" ./gradlew functional:test
```

### Run the non-functional tests against deployed application

For a local run: 

```
SERVICE_ENDPOINT="http://localhost:8080" k6 run ./nft/ramp-up/test.js
```


### Support for Kubernetes
Helm charts have been created for ref-app and it's dependencies that deploy the reference-app and DB. There are chart tests that execute both the NFT and Functional tests.
Some parameters like the registry still need to be manually changed, like the `registry` (with localhost as default) inside the Makefile. After that you can run the commands:
```shell
make docker-build-push-all
make helm-deploy
make helm-test
```
You can also pass registry at runtime as an argument to Makefile, for ex: 
```
REGISTRY=minikube:5000 make <target you want to execute>
```
  