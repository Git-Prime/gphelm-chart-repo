Rancher Charts
==============
This repository includes the charts used in the rancher deployment of GitPrime.
As such, it has some differences from a vanilla Helm chart.
Specifically, each app has an `<app>/<version>` folder.
See https://github.com/rancher/charts for more details.


## Helm Releases

The `releases` folder is hooked into [fluxcd](https://github.com/fluxcd/flux), where each subfolder (test, prod, sandbox) is tied to its respective environment/k8s-cluster. To deploy your app to an environment (assuming flux/helm-operator is installed in the cluster), you would create a HelmRelease file in the environment you want to deploy to. You can override values in this file, point to a specific chart version, pin to a specific branch, etc. The documentation
[here](https://github.com/fluxcd/helm-operator-get-started) is a good intro to how helm-operator works with flux and here are some more [details on HelmRelease CRD](https://docs.fluxcd.io/projects/helm-operator/en/latest/references/helmrelease-custom-resource.html).

A typical workflow for this would be to update your helmrelease (`releases/<env>/your_app.yaml`) with a new image tag or chart version and open a PR on this repo. Once it is merged into master, your application would sync on the kubernetes side (because flux is constantly polling this repo) and the new image or chart updates would be deployed.
