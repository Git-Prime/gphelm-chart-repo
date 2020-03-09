## Overview
The CLI tool [ct](https://github.com/helm/chart-testing) and [kind](https://github.com/kubernetes-sigs/kind) make up the foundation of continuous integration and delivery for helm charts. `ct` automatically detects changed charts so when its called to `lint` or `install`, it will only do so with changes on your branch.

There are additional pieces (bash scripts...) in place to handle things like setting up your test environment, should your chart have any dependencies that can't be specified in the chart itself.

We will now package (`helm package`) and release (`aws s3 sync`) charts properly. This means that a PR merged to master will package your chart and push to our S3 Helm Repo at `https://gitprime-helm-charts.s3-us-west-2.amazonaws.com/`. This bucket is currently public but we can add basic auth to it.

## Chart structure

The basic structure of your chart should look something like this:
```
├── Chart.yaml
├── README.md
├── ci
│   ├── pre-test.sh
│   └── test-values.yaml
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   └── tests
│       ├── test-configmap.yaml
│       └── test-status.yaml
└── values.yaml
```

- `ci/test-values.yaml` (required) - `ct` will uses these values when it tests. You can specify multiple test values and it will test all of them. It looks for files named `*-values.yaml`.
- `ci/pre-test.sh` (optional) - Put anything in here (for example `kubectl` or `helm` commands) that you want to be installed or added to the cluster before your chart is created.
- `templates/tests/test-configmap.yaml` - Is just a configmap that in this case is being used to drop in `bats` tests for the `test-status.yaml` pod.
- `templates/tests/test-status.yaml` (recommended)- Is a pod that uses the `"helm.sh/hook": test-success` annotation which means this pod will be created after your chart is installed to test whatever you want it to test (HTTP connection, database setup, etc).

## Integration Testing
Integration tests are run at the docker-in-docker container level:

    > sandbox-k8s-cluster
        > jenkins-build-pod
            > docker-in-docker container
                > kind cluster
                    > your-chart-pod
                    > your-testing-pod
                > ct container

- A Jenkins "build pod" is created (using the kubernetes Jenkins agent), containing the following containers:
    - `shellcheck` - used to test/validate bash scripts in the `test` folder before proceeding
    - `charts-ci` (ct) - contains the `ct` binary and other dependencies
    - `dind` - docker-in-docker container which runs the `kind` cluster and whatever other docker containers get created.
- The integration testing is done by calling the `test/e2e-kind.sh` script in the `dind` container. This script does the following:
    - Starts a `ct` container which is used going forward for helm/kubectl/bash/etc commands against the kind cluster.
    - Creates a `kind` cluster where your charts' workloads will be deployed to
    - Runs `ct install` on your chart. This will automatically use whatever tests you've defined within your chart and also use whatever values for CI you have defined. Getting this ironed out can take a fair amount of work depending on how your chart is currently written.
- If the branch is master, a package and sync script will be called to package the modified chart(s), run `helm index` and upload `index.yaml` and the chart(s) to our helm repo in S3.

## Local Development
Local development can be done easily by calling the `test/e2e-kind.sh` script locally - it will work on your laptop as long as you have `kind` and `docker` installed. It will automatically detect your local changes and run the end-to-end tests against them.

## Packaging and Releasing
Packaging and releasing is done using `test/package-and-sync.sh`, which does a few things:
- Runs `helm dependency build <your chart>`
- Runs `helm package <your-chart>`
- Runs `helm repo index` with a merge strategy to update `index.yaml`
- Runs `aws s3 sync` to upload `index.yaml` and `<your-chart>.tgz`

## Integration with your application

The benefit we will have from using CI/CD with our helm charts is it will make integration testing with your application possible. `gphelm-chart-repo` is not a real helm repository so we can't `helm repo add` it for testing (or anything else). End-to-end integration testing has been proved out in the `flow-fundamentals` project using the proof-of-concept outlined in this proposal.

## Changes to current workflow
- We would not be versioning within the chart directory - this will break chart testing.
- Use a PR driven workflow. Version bumps will be made using Chart.yaml and merging a PR branch into master, which will package and release your chart to our actual S3-based helm repository.
- Your chart should adhere to valid schema and pass `ct lint` as well as `ct install`
- Master branch will be protected and status checks enforced to ensure parity with the chart code in the GitHub repository and the packaged chart in the helm repo.

## Possible Issues

- I am not sure how well this will integrate into the current Rancher-based release workflow. I am biased to recommend flux/helm-operator for continuous delivery.
- This is going to cause a bit of pain to implement and may have a steep learning curve, but there are a lot of examples of this working within GitPrime and also Pluralsight.
