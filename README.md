# Deploying Netskope Cloud Exchange using Helm

<div style="text-align: justify">
The Netskope Cloud Exchange (CE) provides customers with powerful integration tools to leverage investments across their security posture.

Cloud Exchange consumes valuable Netskope telemetry and external threat intelligence and risk scores, enabling improved policy implementation, automated service ticket creation, and exportation of log events from the Netskope Security Cloud.

To learn more about Netskope Cloud Exchange please refer to the [Netskope Cloud Exchange](https://www.netskope.com/products/capabilities/cloud-exchange) introduction page.
</div>

## Table of contents

- [Prerequisites](#prerequisites)
- [Deploying the Netskope CE Helm Chart](#deploying-the-netskope-ce-helm-chart)
- [Deleting the Netskope CE Helm Chart](#deleting-the-netskope-ce-helm-chart)
- [Configurations](#configurations)
  - [Common Configurations](#common-configurations)
  - [MongoDB Configurations](#mongodb-configurations)
  - [RabbitMQ Configurations](#rabbitmq-configurations)
  - [Core Configurations](#core-configurations)
  - [UI Configurations](#ui-configurations)
- [Override the Default Values](#override-the-default-values)
- [Updating Deployment](#updating-deployment)
- [Using Persistent Volumes](#using-persistentv-volumes)
- [Package Sizing Matrix (Horizontally-scaled Approach)](#package-sizing-matrix-horizontally-scaled-approach)
- [Deploy with Vertically-scaled Approach](#deploy-with-vertically-scaled-approach)
- [Package Sizing Matrix (Vertically-scaled Approach)](#package-sizing-matrix-vertically-scaled-approach)
- [Comparison of Vertical-scaling v/s Horizontal-scaling Compute Requirements)](#comparison-of-vs-hs)
- [Testing Matrix](#testing-matrix)
- [Migrating CE v4.2.0 to CE v5.0.0](migrating-ce-v4.2.0-to-c3-v5.0.0)
- [Restoring MongoDB Data](#restoring-mongodb-data)
- [Troubleshooting](#troubleshooting)
  - [RabbitMQ Split Brain (Network Partitions)](#rabbitmq-split-brain-network-partitions)

## Prerequisites <a name="prerequisites"></a>
The following prerequisites are required to deploy the Netskope Cloud Exchange using helm.
- `K8s` cluster (EKS, OpenShift, etc.) is required to deploy Netskope CE on that.
- `kubectl` must be installed on your machine.
- `helm` must be installed on your machine.
- Namespace should be created before we deploy the helm chart.
- Persistent Volume (PV) provisioner support in the underlying infrastructure (Note: At least two PVs must be present with ReadWriteMany access mode and we only support shared volumes because in order to support horizontal scaling in CE v5.0.0, the core and worker pods require shared volumes).
- Please refer to the section [Package Sizing Matrix](#package-sizing-matrix) before proceeding deployment. 

<br/>

## Deploying the Netskope CE Helm Chart <a name="deploying-the-netskope-ce-helm-chart"></a>

> **FYI:** A `Release` is an instance of a chart running in a Kubernetes cluster. One chart can often be installed many times into the same cluster. And each time it is installed, a new release is created. The release name should contain lower-letters, numbers, and hyphens only.

Before installing the actual product helm chart, we have to deploy the Kubernetes operator for MongoDB and RabbitMQ.
> **Note:** If we are deploying the helm chart on the `Openshift` at that time we will have to provide privileged access to some service accounts before the deploy helm chart. We have mentioned those service account names here `mongodb-database`, `mongodb-kubernetes-operator`, `netskope-ce-rabbitmqcluster-server`, `rabbitmq-operator-rabbitmq-cluster-operator`, `rabbitmq-operator-rabbitmq-messaging-topology-operator` and the service account that you are providing (if you are not providing the service account then provide the privileged access to this `netskope-ce-serviceaccount` that we are creating by default). Skip this step if you are not on the `Openshift`.
To provide the privileged access to the above service accounts, run the below command.
```
oc adm policy add-scc-to-user privileged system:serviceaccount:<namespace-name>:<service-account-name>
```

To install MongoDB Community Operator: 
```
helm repo add mongodb https://mongodb.github.io/helm-charts 
helm install community-operator mongodb/community-operator -n <namespace-name>
```

To install RabbitMQ Cluster Kubernetes Operator:
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install rabbitmq-operator bitnami/rabbitmq-cluster-operator -n <namespace-name> --set msgTopologyOperator.replicaCount=0
```
To install the chart:
```bash
$ helm install <release-name> . -n <namespace-name>
```
For example, installing the chart with release name `my-release`:
```
helm install my-release . -n <namespace-name>
```
The above command deploys Netskope Cloud Exchange. The [Configurations](#configurations) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

<br/>

## Deleting the Netskope CE Helm Chart <a name="deleting-the-netskope-ce-helm-chart"></a>

To uninstall/delete the deployment:
```bash
helm delete <release-name> -n <namespace-name>
```
For example, uninstalling the chart with release name `my-release`:
```
helm uninstall my-release -n <namespace-name>
```
The command removes all the Kubernetes components associated with the chart and deletes the release.

<br>

## Configurations <a name="configurations"></a>
### Common Configurations (these configurations will be applied on all pods) <a name="common-configurations"></a>
<div style="text-align: justify">

| Name                     | Description                                                                                               | Default Value           | Required    |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | --------------- | ----------- |
| `commonLabels`           | Add labels to all the deployed resources (sub-charts are not considered). Evaluated as a template         | `{}`            | No          | 
| `commonAnnotations`           | Common annotations to add to all resources. Evaluated as a template                                  | `{}`            | No          |
| `namespace`              | Namespace name which all resources are running in                                                         | `""`       | No          |
| `serviceAccount.create`  | Enable creation of ServiceAccount for all pods                                                            | `true`          | No          |
| `serviceAccount.name`    | Name of the created serviceAccount                                                                        | `""`            | No          |
| `serviceAccount.annotations`                  | Additional Service Account annotations                                               | `{}`            | No          |
| `serviceAccount.automountServiceAccountToken` | Allows auto mount of ServiceAccountToken on the serviceAccount created               | `false`         | No          |
| `privateImageRegistry.imagePullSecrets` | If your image registry is private, in that case, you have to pass imagePullSecrets, Secrets must be manually created in the namespace | `[]`           | No          |
| `updateStrategy`         | Strategy to use to replace existing pods                                                                 | <pre>type: <br/>RollingUpdate</pre> | No           |


### MongoDB Configurations <a name="mongodb-configurations"></a>
| Name                     | Description                                                                                               | Default Value           | Required    |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | --------------- | ----------- |
| `mongodb.labels`         | Additional labels to be added to the MongoDB statefulset                                             | `{}`            | No          |
| `mongodb.annotations`    | Additional annotations to be added to the MongoDB statefulset                                             | `{}`            | No          |
| `mongodb.image`          | Docker image of MongoDB statefulset                                                                       | `index.docker.io/mongo:5.0.21` | No          |
| `mongodb.initContainers.volumePermissionContainer.create` | Creates init containers will use for change the mount volume permission and ownership | `false`           | No          |
| `mongodb.initContainers.image` | Init containers image | `busybox:latest`           | No          |
| `mongodb.resources`      | Resources request and limit for MongoDB (**Note:** These are default configurations for a low data volume (Extra Small Netskope CE Package Type). The end user may want to change these values as per the underlying use case and data volume on their end (based on the associated Netskope CE Package Type). While doing that, please ensure that the underlying cluster nodes should also have a cumulative sufficient compute power for this change to work seamlessly. For more details on the Netskope CE Package Types, please refer to the [Package Sizing Matrix](#package-sizing-matrix) section)                                                                    |  <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | No          |
| `mongodb.replicaCount`   | No. of replica of MongoDB                                                                                  | `3`             | No          |        
| `mongodb.securityContext.privileged` | Privileged containers can allow almost completely unrestricted host access                    | `false`         | No          |
| `mongodb.securityContext.allowPrivilegeEscalation` | Enable privilege escalation, it should be true if privileged is set to true.    | `false`         | No          |
| `mongodb.persistence.size` | PVC Storage Request for MongoDB data volume                                                             | `3Gi`           | No          |
| `mongodb.persistence.storageClassName` | PVC Storage Class for MongoDB data volume                                                   | `manual`        | No          |
| `mongodb.persistence.annotations` | PVC annotations                                                                                  | `{}`            | No          |
| `mongodb.auth.replicaSetKey` | Key used for authentication in the replicaset                                                         | `""`            | Yes         |
| `mongodb.auth.rootUser` | MongoDB root username                                                                                      | `""`            | Yes         |   
| `mongodb.auth.rootPassword` | MongoDB root password                                                                                  | `""`            | Yes         |
| `mongodb.auth.cteAdminUser` | MongoDB cteAdmin User          | `""`            | Yes         |
| `mongodb.auth.cteAdminPassword` | MongoDB cteAdminPassword password                                                                   | `""`            | Yes         |
| `mongodb.secrets.root.create` |  Enable to create MongoDB root secret                                                                 | `true`          | No         |
| `mongodb.secrets.root.name` | Name of the MongoDB Root secret                                                      |`"netskope-ce-mongodb-root-secret"` | No         |
| `mongodb.secrets.cte.create` |  Enable to create MongoDB cte secret                                                                 | `true`          | No         |
| `mongodb.secrets.cte.name` | Name of the MongoDB cte secret                                                      |`"netskope-ce-mongodb-cre-secret"` | No         |


### RabbitMQ Configurations <a name="rabbitmq-configurations"></a>
| Name                     | Description                                                                                               | Default Value           | Required    |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | --------------- | ----------- |
| `rabbitmq.labels`        | Additional labels to be added to the RabbitMQ statefulset                                            | `{}`            | No          |
| `rabbitmq.annotations`    | Additional annotations to be added to the RabbitMQ statefulset                                           | `{}`            | No          |
| `rabbitmq.initContainers.image`| docker image of init containers                                                 | `"busybox:latest"`            | No          |
| `rabbimq.initContainers.volumePermissionContainer.create`       | Creates init containers will use for change the mount volume permission and ownership                                                 | `false`            | No          |
| `rabbitmq.image`         | Docker image of RabbitMQ statefulset                                                                      | `index.docker.io/rabbitmq:3.12.6-management` | No          |
| `rabbitmq.replicaCount`         | No. of replica of RabbitMQ                                                                      | `3` | No          |  
| `rabbitmq.resources`     | Resources request and limit for RabbitMQ (**Note:** These are default configurations for a low data volume (Extra Small Netskope CE Package Type). The end user may want to change these values as per the underlying use case and data volume on their end (based on the associated Netskope CE Package Type). While doing that, please ensure that the underlying cluster nodes should also have a cumulative sufficient compute power for this change to work seamlessly. For more details on the Netskope CE Package Types, please refer to the [Package Sizing Matrix](#package-sizing-matrix) section)                                                                    |  <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> |  No          |       
| `rabbitmq.securityContext.privileged` | Privileged containers can allow almost completely unrestricted host access                   | `false`         | No          |
| `rabbitmq.securityContext.allowPrivilegeEscalation` | Enable privilege escalation, it should be true if privileged is set to true    | `false`         | No          |
| `rabbitmq.persistence.size` | PVC Storage Request for RabbitMQ data volume                                                           | `3Gi`           | No          |
| `rabbitmq.persistence.storageClassName` | PVC Storage Class for Rabbitmq data volume                                                 | `manual`        | No          |
| `rabbitmq.persistence.annotations` | PVC annotations                                                                                 | `{}`            | No          |
| `rabbitmq.auth.rabbitmqDefaultUser` | RabbitMQ Default User                          | `""`            | Yes         |
| `rabbitmq.auth.rabbitmqPassword` | RabbitMQ password                                                                                 | `""`            | Yes         |
| `rabbitmq.secrets.create` |  Enable to create Rabbitmq secret                                                                 | `true`          | No         |
| `rabbitmq.secrets.name` | Name of the RabbitMQ secret                                                      |`"netskope-ce-rabbitmq-secret"` | No         |

### Core Configurations <a name="core-configurations"></a>
| Name                     | Description                                                                                               | Default Value           | Required    |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | --------------- | ----------- |
| `core.labels`            | Additional labels to be added to the Core deployment                                                 | `{}`            | No          |
| `core.annotations`       | Additional annotations to be added to the Core deployment                                                 | `{}`            | No          |
| `core.initContainers.volumePermissionContainer.create`       | Creates init containers will use for change the mount volume permission and ownership                                                 | `false`            | No          |
| `core.rbac.create`       | Whether to create & use RBAC resources or not, binding ServiceAccount to a role                           | `true`          | No          |
| `core.rbac.rules`        | Custom rules to create following the role specification                                                   | `[]`            | No          |
| `core.image`             | Docker image of Core                                                                                      | `netskopetechnicalalliances/cloudexchange:core5-latest` | No          |
| `core.replicaCount.core` | No. of replica count for Core                                                                          | `1`             | No          |
| `core.replicaCount.worker` | No. of replica count for Worker                                                                      | `2`             | No          |
| `core.proxy.enable`  | To enable proxy in Core                                                                              | `false`         | No          |
| `core.proxy.url`     | Proxy URL                                                                                            | `""`            | If `core.proxy.enable: true` |
| `core.resources.core`         | Resources request and limit for Core (**Note:** These are default configurations for a low data volume (Extra Small Netskope CE Package Type). The end user may want to change these values as per the underlying use case and data volume on their end (based on the associated Netskope CE Package Type). While doing that, please ensure that the underlying cluster nodes should also have a cumulative sufficient compute power for this change to work seamlessly. For more details on the Netskope CE Package Types, please refer to the [Package Sizing Matrix](#package-sizing-matrix) section)                                                                   |  <pre>limits: <br/> memory: 2Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1Gi <br> cpu: 500m </pre> | No            |   
| `core.resources.worker`         | Resources request and limit for Core (**Note:** These are default configurations for a low data volume (Extra Small Netskope CE Package Type). The end user may want to change these values as per the underlying use case and data volume on their end (based on the associated Netskope CE Package Type). While doing that, please ensure that the underlying cluster nodes should also have a cumulative sufficient compute power for this change to work seamlessly. For more details on the Netskope CE Package Types, please refer to the [Package Sizing Matrix](#package-sizing-matrix) section)                                                                   |  <pre>limits: <br/> memory: 3500Mi <br/> cpu: 2000m <br/>requests: <br> memory: 1500Mi <br> cpu: 1000m </pre> | No            |             
| `core.securityContext.privileged` | Privileged containers can allow almost completely unrestricted host access                       | `false`         | No          |
| `core.securityContext.allowPrivilegeEscalation` | Enable privilege escalation, it should be true if privileged is set to true        | `false`         | No          |
| `core.persistence.size` | PVC Storage Request for Core data volume                                                           | `3Gi`           | No          |
| `core.persistence.storageClassName` | PVC Storage Class for Core data volume                                                 | `manual`        | No          |
| `core.persistence.annotations` | PVC annotations                                                                                 | `{}`            | No          |
| `core.caCertificate` | Enable the private CA certificate                                                                         | `false`            | No          |
| `core.auth.analyticsToken` | Analytics Token                                                                                         | `""`            | Yes         |
| `core.auth.jwtToken` | JWT Token                                                                                                     | `""`            | Yes         |
| `core.secrets.core.create` |  Enable to create Core secret                                                                 | `true`          | No         |
| `core.secrets.core.name` | Name of the Core secret                                                      |`"netskope-ce-core-secret"` | No         |
| `core.secrets.caCertificate.create` | Enable to create CA Certificate secret                                     | `true`          | No         |
| `core.secrets.caCertificate.name` | Name of the CA Certificate secret                                            |`"netskope-ce-ca-certificate-secret"` | No         |
| `core.workerConcurrency` | Set concurrency horizontal scaling                                            |`3` | No         |
| `core.rabbitmqAvailableStorage` | Rabbitmq available storage                                           |`40` | No         |


> Note: If the `core.caCertificate` attribute is enabled (Default: false) then the CA certificate should be present in the `ca-certificates` directory with the `ca.pem` file name.

### UI Configurations <a name="ui-configurations"></a>
| Name                     | Description                                                                                               | Default Value           | Required    |
| ------------------------ | --------------------------------------------------------------------------------------------------------- | --------------- | ----------- |
| `ui.labels`              | Additional labels to be added to the UI deployment                                                   | `{}`            | No          |
| `ui.annotations`         | Additional annotations to be added to the UI deployment                                                 | `{}`            | No          |
| `ui.rbac.create`         | Whether to create & use RBAC resources or not, binding ServiceAccount to a role                           | `true`          | No          |
| `ui.rbac.rules`          | Custom rules to create following the role specification                                                   | `[]`            | No          |
| `ui.image`               | Docker image of UI                                                                                        | `netskopetechnicalalliances/cloudexchange:ui5-latest` | No
| `ui.replicaCount`        | No. of replica of UI                                                                                      | `2`             | No          |
| `ui.ssl`                 | To enable SSL certificates                                                                                | `false`          | No          |
| `ui.resources`           | Resources request and limit for UI (**Note:** These are default configurations for a low data volume (Extra Small Netskope CE Package Type). The end user may want to change these values as per the underlying use case and data volume on their end (based on the associated Netskope CE Package Type). While doing that, please ensure that the underlying cluster nodes should also have a cumulative sufficient compute power for this change to work seamlessly. For more details on the Netskope CE Package Types, please refer to the [Package Sizing Matrix](#package-sizing-matrix) section)                                                                    |  <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | No           |
| `ui.securityContext.privileged` | Privileged containers can allow almost completely unrestricted host access                         | `false`         | No          |
| `ui.securityContext.allowPrivilegeEscalation` | Enable privilege escalation, it should be true if privileged is set to true.         | `false`         | No          |
| `ui.secrets.create` |  Enable to create UI secret                                                                 | `true`          | No         |
| `ui.secrets.name` | Name of the UI secret                                                     |`"netskope-ce-ui-secret"` | No         |

> Note: If you enable `ui.ssl` certificates (Default: false), your SSL certificates and certificate & certificate private key (with the respective names `cte_cert.key` and `cte_cert_key.key`) must be present in the certificates directory at the root.

<br/>
</div>

## Override the Default Values <a name="override-the-default-values"></a>

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install my-release . --set mongodb.auth.rootPassword=secretpassword 
```

The above command sets the MongoDB `root` account password to `secretpassword`.

> NOTE: Once this chart is deployed, it is not possible to change the application's access credentials, such as usernames or passwords, using Helm. To change these application credentials after deployment, delete any persistent volumes (PVs) used by the chart and re-deploy it, or use the application's built-in administrative tools if available.
Alternatively, create a `values-override.yaml` YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install my-release -f sample-values-override.yaml . -n <namespace-name>
```

> **Tip**: You can refer to the default [values.yaml](values.yaml) to get a list of all the helm chart parameters that could be overridden in the override file (refer to the [sample-values-overrride-hs.yaml](./sample-values-override-hs.yaml)) (refer to the [sample-values-override-openshift-hs.yaml](./sample-values-override-openshift-hs.yaml) for the OpenShift deployment).

<br/>

## Updating Deployment <a name="updating-deployment"></a>
To override, update the [sample-values-override.yaml](./sample-values-override.yaml) file with the required values and execute the below command.

```bash
$ helm upgrade my-release -f sample-values-override.yaml . -n <namespace-name>
```

> **Note:** There could be more values that could be needed to be overridden by the end-user based on their use case. For that, please add respective configurations in the sample-overrides file before running the below command. The sample-override file is just for the end user's fundamental reference.

<br/>

## Accessing Netskope CE <a name="accessing-netskope-ce"></a>
To access Netskope CE using port forward, run the below command.

```
kubectl port-forward service/<ui-service-name> 8080:80 -n <namespace-name>
```
> **Tip:** To get UI service name run this command `kubectl get svc -n <namespace-name>`.

Now, go to any browser and enter the below URL in search box.
```
https://localhost:8080/login
```

![](./media/login-screen.png)

<br/>

## Using Persistent Volumes <a name="using-persistentv-volumes"></a>

<div style="text-align: justify">
There are different types of persistent volumes that can be attached to a Kubernetes deployment. In the below section, we demonstrate the use case of persistent volumes by referencing Amazon Elastic Kubernetes Service (EKS) and Amazon Elastic File System (EFS). Please refer to the prerequisites section before jumping into the detailed steps below.
</br>

### Prerequisites
<div style="text-align: justify">
An AWS IAM Role with required permissions should be [created and configured](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html#efs-create-iam-resources) in your Kubernetes cluster Service Account deployment YAML file to allow the Amazon EFS driver to interact with your file system.
</div>
</br>

### Step 1
[Create Amazon EFS](https://docs.aws.amazon.com/efs/latest/ug/gs-step-two-create-efs-resources.html) in AWS and get its file system ID. 

### Step 2
Install AWS EFS CSI Driver in the Kubernetes cluster (in this case Amazon EKS cluster). To install the driver, follow the below documentation.

https://github.com/kubernetes-sigs/aws-efs-csi-driver

> **Note:** Based on the current latest version of AWS EFS CSI Driver (v1.7.0), the Kubernetes version should be `>=v1.17`. Though at any point in time, the compatibility versions of Kubernetes and AWS EFS CSI Driver can be identified from the above link.

### Step 3
Create `StorageClass` in the Kubernetes deployment YAML file as mentioned below. In that StorageClass `directoryPerms` should be `700` and `gid` and `uid` should be `1001`.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: <sc-name>
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: <fs-id>
  directoryPerms: "700"
  gid: "1001"
  uid: "1001"
```

### Step 4
Pass StorageClass name (sc-name) in the `values-override.yaml` file as mentioned below in the `MongoDB` and `RabbitMQ` sections.
```yaml
mongodb:
  persistence:
    storageClassName: sc-name
rabbitmq:
  persistence:
    storageClassName: sc-name
core:
  persistence:
    storageClassName: sc-name
```

### Step 5
Install the helm chart by following the steps mentioned in the above section [here](#deploying-the-netskope-ce-helm-chart).

<br/>
</div>

## Package Sizing Matrix (Horizontally-scaled Approach) <a name="package-sizing-matrix-horizontally-scaled-approach"></a>

This section depicts the required CPUs and Memory for containers based on the Netskope Cloud Exchange package types depending on the use case for a horiozontally-scaled approach.

| Package Type | # of Core Contianers | Core Container Resources | # of Worker Containers | Worker Container Resources | # of UI Containers | UI Container Resources | # of MongoDB Containers | MongoDB Container Resources | # of RabbitMQ Containesr | RabbitMQ Container Resources | Worker Concurrency | RabbitMQ Available Storage |
| ------------ | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- |
| Extra Small  | 1 | <pre>limits: <br/> memory: 2Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1Gi <br> cpu: 500m </pre> | 2 | <pre>limits: <br/> memory: 3500Mi <br/> cpu: 2000m <br/>requests: <br> memory: 1500Mi <br> cpu: 1000m </pre> | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 3 | 42949672960 |
| Small  | 1 | <pre>limits: <br/> memory: 2Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1Gi <br> cpu: 500m </pre> | 3 | <pre>limits: <br/> memory: 3500Mi <br/> cpu: 2000m <br/>requests: <br> memory: 1500Mi <br> cpu: 1000m </pre> | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 3 | 42949672960 |
| Medium  | 1 | <pre>limits: <br/> memory: 2Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1Gi <br> cpu: 500m </pre> | 4 | <pre>limits: <br/> memory: 3500Mi <br/> cpu: 2000m <br/>requests: <br> memory: 1500Mi <br> cpu: 1000m </pre> | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 3 | 85899345920 |
| Large  | 1 | <pre>limits: <br/> memory: 2Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1Gi <br> cpu: 500m </pre> | 5 | <pre>limits: <br/> memory: 3500Mi <br/> cpu: 2000m <br/>requests: <br> memory: 1500Mi <br> cpu: 1000m </pre> | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 3 | 128849018880 |
| Extra Large  | 1 | <pre>limits: <br/> memory: 2Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1Gi <br> cpu: 500m </pre> | 8 | <pre>limits: <br/> memory: 3500Mi <br/> cpu: 2000m <br/>requests: <br> memory: 1500Mi <br> cpu: 1000m </pre> | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 3 | 171798691840 |


Please take a look at the [sample-values-override-hs](./sample-values-override-hs.yaml) file that shows how to override the default values. To deploy the Helm Chart with the override file, refer to the section [Override the Default Values](#override-the-default-values).

<br/>

## Deploy with Vertically-scaled Approach <a name="deploy-with-vertically-scaled-approach"></a>

To deploy Netskope CE using a vertically-scaled approach, where the number of core containers is set to 1 and the number of worker containers is set to 0, follow the configurations in the below section [Package Sizing Matrix (Vertically-scaled Approach)](#package-sizing-matrix-vertically-scaled-approach).

Set the number of core containers
- Specify the `core.replicaCount.core` value as 1 in the configuration
- Ensure that the deployment only includes a single core container to handle the workload

Disable the worker containers
- Set the `core.replicaCount.worker` value as 0 in the configuration
- This ensures that no worker containers are deployed in the environment

By applying these specific configurations, you can deploy Netskope CE with a vertically-scaled approach, optimizing the deployment for a single core container without any worker containers.

> **Tip**: You can refer to the default [values.yaml](values.yaml) to get a list of all the helm chart parameters that could be overridden in the override file (refer to the [sample-values-overrride-vs.yaml](./sample-values-override-vs.yaml)) (refer to the [sample-values-override-openshift-vs.yaml](./sample-values-override-openshift-vs.yaml) for the OpenShift deployment).

<br/>

## Package Sizing Matrix (Vertically-scaled Approach) <a name="package-sizing-matrix-vertically-scaled-approach"></a>

This section depicts the required CPUs and Memory for containers based on the Netskope Cloud Exchange package types depending on the use case for a vertically-scaled approach.

| Package Type | # of Core Contianers | Core Container Resources | # of Worker Containers | # of UI Containers | UI Container Resources | # of MongoDB Containers | MongoDB Container Resources | # of RabbitMQ Containesr | RabbitMQ Container Resources | Worker Concurrency | RabbitMQ Available Storage |
| ------------ | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- | -------------- |
| Extra Small  | 1 | <pre>limits: <br/> memory: 4Gi <br/> cpu: 4000m <br/>requests: <br> memory: 2Gi <br> cpu: 2000m </pre> | 0 | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 6 | 42949672960 |
| Small  | 1 | <pre>limits: <br/> memory: 8Gi <br/> cpu: 6000m <br/>requests: <br> memory: 2Gi <br> cpu: 3000m </pre> | 0 | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 9 | 42949672960 |
| Medium  | 1 | <pre>limits: <br/> memory: 16Gi <br/> cpu: 8000m <br/>requests: <br> memory: 4Gi <br> cpu: 4000m </pre> | 0 | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 12 | 85899345920 |
| Large  | 1 | <pre>limits: <br/> memory: 24Gi <br/> cpu: 12000m <br/>requests: <br> memory: 8Gi <br> cpu: 4000m </pre> | 0 | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 18 | 128849018880 |
| Extra Large  | 1 | <pre>limits: <br/> memory: 48Gi <br/> cpu: 24000m <br/>requests: <br> memory: 8Gi <br> cpu: 4000m </pre> | 0 | 2 | <pre>limits: <br/> memory: 250Mi <br/> cpu: 750m <br/>requests: <br> memory: 125Mi <br> cpu: 325m </pre> | 3 | <pre>limits: <br/> memory: 1Gi <br/> cpu: 2000m <br/>requests: <br> memory: 500Mi <br> cpu: 1000m </pre> | 3 | <pre>limits: <br/> memory: 3Gi <br/> cpu: 1000m <br/>requests: <br> memory: 1500Mi <br> cpu: 500m </pre> | 36 | 171798691840 |
<br/>

## Comparison of Vertical-scaling v/s Horizontal-scaling Compute Requirements <a name="comparison-of-vs-hs"></a>

This section depicts the comparison of the underlying (nodes) compute power required in both the approaches of CE deployment (Vertically-scaled v/s Horizontally-scaled). Here, we have considered the High Availability (HA) aspects while desgining the cluster and the helm configurations.

| Package Type | Vertical-scaling Benchmarking     | Horizontal-scaling Benchmarking  |
| ------------ | --------------------------------- | -------------------------------- |
| Extra Small  | 3 Nodes, 8 Core and 16 GB Memory (Total 24 Core and 48 Memory)  | 6 Nodes, 4 Core and 8 GB Memory (Total 24 Core and 48 Memory) | 
| Small        | 3 Nodes, 8 Core and 16 GB Memory (Total 24 Core and 48 Memory) | 7 Nodes, 4 Core and 8 GB Memory (Total 28 Core and 56 Memory)  | 
| Medium       | 3 Nodes, 16 Core and 32 GB Memory (Total 48 Core and 96 Memory) | 8 Nodes, 4 Core and 8 GB Memory (Total 32 Core and 64 Memory)  |
| Large        | 3 Nodes, 32 Core and 64 GB Memory (Total 96 Core and 192 Memory) | 9 Nodes, 4 Core and 8 GB Memory (Total 36 Core and 72 Memory)  |
| Extra Large  | 3 Nodes, 32 Core and 64 GB Memory (Total 96 Core and 192 Memory) | 10 Nodes, 4 Core and 8 GB Memory (Total 40 Core and 80 Memory) | 

<br/>

## Testing Matrix <a name="testing-matrix"></a>

This section depicts the container orchestration platforms and CE version on which we have tested the current Helm chart.

| Vendor       | Container Orchestration Platform | Host OS | Component Versions        | Component Configurations                               |
| ------------ | -------------------------------- | ------- | ------------------------- | ------------------------------------------------------ |
| Kubernetes   | Kubernetes                       | RHEL    | RHEL                      | 8 Node, 4 Cores CPU and 8 GB Memory and Medium Package, NFS as a Persistent Volume |
| Kubernetes   | Kubernetes                       | CentOS  | CentOS 7                  | 8 Node, 4 Cores CPU and 8 GB Memory and Medium Package, NFS as a Persistent Volume |
| Kubernetes   | Kubernetes                       | Ubuntu  | Ubuntu 20.04              | 8 Node, 4 Cores CPU and 8 GB Memory and Medium Package, NFS as a Persistent Volume |
| OpenShift    | OpenShift                        | RHEL    | 4.11.39 Openshift         | 8 Node, 4 Cores CPU and 8 GB Memory and Medium Package, NFS as a Persistent Volume |

| Container Name | Image Tag                                           | Version | 
| ---------------| --------------------------------------------------- | ------- |
| Core           | [netskopetechnicalalliances/cloudexchange:core5-latest](https://hub.docker.com/layers/netskopetechnicalalliances/cloudexchange/core5-latest/images/sha256-f27d626adb718e6fd84234a44febedd15239ef14b20da90cfbb8cf2813f578b0?context=explore) | 5.0.0       | 
| UI           | [netskopetechnicalalliances/cloudexchange:ui5-latest](https://hub.docker.com/layers/netskopetechnicalalliances/cloudexchange/ui5-latest/images/sha256-e75319d05270c7d3b8838c933ca10295b945bdce177c79ec38247e10e96056f7?context=explore) | 5.0.0        | 
| MongoDB        | [index.docker.io/mongo:5.0.21](https://hub.docker.com/layers/library/mongo/5.0.21/images/sha256-db6fabcdc5e0f2ef20584acb238169f051158bcc35b33a4cc217441396724435?context=explore) | 5.0.21        | 
| RabbitMQ        | [index.docker.io/rabbitmq:3.12.6-management](https://hub.docker.com/layers/library/rabbitmq/3.12.6-management/images/sha256-11bb72ba60467447335e157b1f785d67d295de5dc74590942622817fca524254?context=explore) | 3.12.6-management | 

<br/>

## Migrating CE v4.2.0 to CE v5.0.0 <a name="migrating-ce-v4.2.0-to-c3-v5.0.0"></a>

### Notes
<div style="text-align: justify">

- Please be aware that during the migration process, there will be no data loss for the custom plugins that have been uploaded. Therefore, there is no need to re-upload those custom plugins, and you do not need to back up and retain any critical custom plugins before the migration.

- **Modify Configuration:** Make necessary changes to configurations, which means get latest helm chart for CE v5.0.0.
- **Update to CE v5.0.0:** Follow the appropriate update procedure to migrate to CE v5.0.0.
- **Verify Migration:** Conduct thorough testing to ensure the migration was successful and all functionalities are intact.
- **Complete Post-Migration Tasks:** Inform stakeholders about the completion of the migration and perform specific post migration steps if any based on the end-users use-case 
</div>
<div style="text-align: justify">
By following these steps, you can migrate to CE v5.0.0 while minimizing disruptions and ensuring a smooth transition for your system.

- Download the Helm chart for CE v5.0.0 and make any necessary modifications to the chart's values or configuration files if required. Once the changes have been done, deploy the updated Helm chart to implement the desired changes in your CE environment.
  ```
  helm upgrade <release-name> . -n <namespace> -f <values-override-file>
  ```

- Retrieve Mongodb statefulset pods name.
  ```
  kubectl get pods -n <namespace> 
- Using the retrieved mongodb statefulset pods name from the previous step, delete the Mongodb Statefulset pods in reverse order (wait untill the deleted pod starts again with new image and becomes healthy before deleting the next pod.) using the following command.
  ```
  kubectl delete pod <mongodb-statefulset-pod-name> -n <namespapce>  
- After the successful migration to v5.0.0, ensure that the MongoDB and RabbitMQ StatefulSets have completed the rolling update, resulting in the creation of new containers for the Core and Worker components. Perform a series of sanity tests to verify the functionality and stability of the migrated system. Additionally, check the CE version from the CE user interface to confirm the successful migration and ensure that the updated version v5.0.0 is reflected.
</div>

## Restoring MongoDB Data <a name="restoring-mongodb-data"></a>

To restore existing MongoDB data in your newly deployed Netskope CE stack or an upgraded Netskope CE stack, follow the below steps.

### Prerequisites
<div style="text-align: justify">

- Prior to the restore, it is essential to stop data ingestion to maintain data integrity.
- As a part of the restore process, it is necessary to stop the Core and Worker containers to ensure a smooth restore.
- Before proceeding with the restore process, it is crucial to verify that you have successfully created a comprehensive MongoDB dump containing all the necessary data. This backup ensures that you have a reliable and complete snapshot of your MongoDB database to restore from in the event of data loss or corruption.
</div>

### Notes
<div style="text-align: justify">

- Please be aware that during the restore process, there is a data loss for the custom plugins that were uploaded. This is due to the removal of persistent volume claim for Core and Worker containers. Therefore, it will be necessary to reupload those custom plugins after completing the restore to ensure their availability in the updated system. It is advisable to take appropriate measures to back up and retain any critical custom plugins prior to the restore process to mitigate any potential loss of data.
- **Plan for Downtime:** Allocate a maintenance window and inform stakeholders to minimize disruptions.
- **Notify Stakeholders:** Communicate the restore process schedule, expected downtime, and potential impact to stakeholders.
- **Stop Data Ingestion:** Gracefully halt the data ingestion process to prevent data loss or inconsistencies.
- **Stop Core and Worker Deployments:** Properly shut down the core and worker deployments.
- **Verify Data Restore:** Conduct thorough testing to ensure the restore was successful and all functionalities are intact.
- **Complete Post-Restore Tasks:** Inform stakeholders about the completion of the restore and perform specific post restore steps if any based on the end-users use-cases.
</div>
<div style="text-align: justify">
By following these steps, one can minimize disruptions and ensure a smooth restore for their system.

- Retrieve Core and Worker deployments names.
  ```
  kubectl get deployment -n <namespace> 
  ```
>**Note:** As a prerequisite, it is essential to halt data ingestion before proceeding with the deletion of the Core and Worker deployments.
- Using the provided deployments names from the previous step, delete the Core and Worker deployments using the following command.
  ```
  kubectl delete deployment <core-deployment-name> <worker-deployment-name> -n <namespapce>
  ```
- Retrieve Custom plugin PVC name.
  ```
  kubectl get pvc -n <namespcae>
  ```
- After confirming the successful deletion of the Core and Worker containers, proceed to delete the Persistent Volume Claim (PVC) using the appropriate command or method.
  ```
  kubectl delete pvc <custom-plugin-pvc-name> -n <namespace>
  ```
- Deploy a temporary container and ensure you have a backup available in Kubernetes, follow these steps:
  - Prepare the Container Specification:
    - Create a Kubernetes Deployment or Pod definition file (e.g., deployment.yaml) with the necessary specifications.
    - Specify the container image you want to use, including all required software and dependencies.
    - Here we have provided sample pod spec, in which change appropriate values by replacing "<>". 
      ```
      apiVersion: v1
      kind: Pod
      metadata:
        name: restore-mongodb
        namespace: <namespcae-name>
      spec: 
        containers:
          - env:
              - name: MONGO_CONNECTION_STRING
                value: <mongo-db-connection-string>
            image: <image>
            command:
              - sh
            args:
              - -ec
              - |
                sleep 3000;
            imagePullPolicy: IfNotPresent
            name: restore-mongodb
            volumeMounts:
              - name: restore-mongodb
                mountPath: /data
        volumes:
          - name: restore-mongodb
            persistentVolumeClaim:
              claimName: restore-mongodb-pvc
      ```
    - To apply the pod spec file and deploy the pod in Kubernetes, use the following command:
      ```
      kubectl apply -f <spec-file.yaml>
      ```
  - SSH into the that newly created pod using the below command.
    ```
    kubectl exec -it <pod-name> -- /bin/bash
    ```
    Replace \<pod-name> with the actual name of the pod you want to access. This command will open an interactive shell session within the specified pod, allowing you to execute commands and access the container's filesystem.
  - To restore MongoDB data from within the newly created pod, execute the following command after ensuring that the MongoDB dump is available within the container:
    ```
    mongorestore --uri=$MONGO_CONNECTION_STRING --gzip  --archive=<dump-file> --drop;
    ```
- Now that we have successfully restored the data, we can redeploy the actaul helm chart with the required values so that it will automatically detect change and bring the kubernetes resources in its desired state keeping the restored data persistent.
  ```
  helm upgrade <release-name> . -n <namespace> -f <values-override-file>
  ```
- After the successful restore of MongoDB data, perform a series of sanity tests to verify the functionality and stability of the restored system.
</div>

## Troubleshooting <a name="troubleshooting"></a>
<div style="text-align: justify">

### RabbitMQ Split Brain (Network Partitions)
In our setup, we utilize a RabbitMQ cluster consisting of three nodes to achieve high availability. One node is designated as the master, while the other two nodes serve as replicas. Clustering is employed to accomplish various objectives, such as enhancing data safety through replication, improving availability for client operations, and increasing overall system throughput. Optimal configurations may vary depending on specific goals and requirements.

**Problem Statement** 

In a RabbitMQ cluster configuration with multiple nodes, network issues or connectivity problems can lead to a situation where one of the cluster members becomes isolated and operates independently from the rest of the cluster. This causes the cluster to split into separate entities, with each side considering the other side as crashed. This scenario, known as split-brain, creates inconsistencies as queues, bindings, and exchanges can be created or deleted separately on each side of the split, leading to data inconsistency and potential data loss.

**Detecting Split Brain**

Nodes determine if its peer is down if another node is unable to contact it for a period of time, 60 seconds by default. If two nodes come back into contact, both having thought the other is down, the nodes will determine that a partition has occurred. This will be written to the RabbitMQ log in a format similar to below:

```
2020-05-18 06:55:37.324 [error] <0.341.0> Mnesia(rabbit@warp10): ** ERROR ** mnesia_event got {inconsistent_database, running_partitioned_network, rabbit@hostname2}
```

**Recovering from a Split Brain**

To recover from a split-brain, first choose one partition which you trust the most. This partition will become the authority for the state of the system (schema, messages) to use; any changes which have occurred on other partitions will be lost.

Stop all nodes in the other partitions, then start them all up again. When they rejoin the cluster they will restore state from the trusted partition. Follow the below steps to rejoin to the cluster.

>**Note:** In our case rabbitmq node name looks like, rabbit@netskope-ce-rabbitmqcluster-server-0.netskope-ce-rabbitmqcluster-nodes.\<namespace-name>

- SSH in to that RabbitMQ node which is outside of Network.
  ```
  kubectl exec -it <rabbitmq-node-pod-name> -n <namespace> -- /bin/bash
  ```
- Run the below commands into that RabbitMQ node
  ``` 
  rabbitmqctl stop_app
  # => Stopping node rabbit@rabbit2 ...done.

  rabbitmqctl reset
  # => Resetting node rabbit@rabbit2 ...

  rabbitmqctl join_cluster rabbit@rabbit1
  # => Clustering node rabbit@rabbit2 with [rabbit@rabbit1] ...done.

  rabbitmqctl start_app
  # => Starting node rabbit@rabbit2 ...done.
  ```
For more information, refer [RabbitMQ Clustering and Network Partitions](https://www.rabbitmq.com/partitions.html#detecting)

</div>