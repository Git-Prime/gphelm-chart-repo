proficiency-report
==============
This is a standalone process for data-aggregation. The application code is [here](https://github.com/Git-Prime/gp-pyspark).

### Configuration
This application uses [spark-operator](https://github.com/helm/charts/tree/master/incubator/sparkoperator) to run Spark jobs in Kubernetes. If you want multiple jobs, it's best to call this chart multiple times either with helm install or with multiple HelmRelease files and set your values accordingly.

For more information on how these jobs work, see the user guide [here](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md)
